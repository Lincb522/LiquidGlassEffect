import UIKit
import MetalKit

/// Metal glass surface with point-space optics and an immutable captured frame.
public final class LiquidGlassView: MTKView {
    public private(set) var config: LiquidGlassConfig
    public var targetFrameRate: Int = 60 {
        didSet { preferredFramesPerSecond = max(1, targetFrameRate) }
    }
    public var backgroundCaptureFrameRate: Double = 30 {
        didSet { backdropCapture?.captureFrameRate = max(1, backgroundCaptureFrameRate) }
    }
    public var autoCapture = true
    private var forceCaptureRequested = true
    public var touchPoint: CGPoint?
    public var frames: [CGRect] = [] {
        didSet {
            guard frames != oldValue else { return }
            updateShadow()
            setNeedsLayout()
        }
    }
    public weak var groupCoordinator: LiquidGlassGroupCoordinator? {
        didSet {
            guard oldValue !== groupCoordinator else { return }
            oldValue?.removeChild(id: captureID)
            backdropCapture?.releaseAll()
            groupCoordinator?.invalidate()
        }
    }
    public private(set) var isMetalAvailable = false

    private let captureID = UUID()
    private var commandQueue: MTLCommandQueue?
    private var backdropCapture: BackdropCapture?
    private let blurPass = LiquidGlassBlurPass()
    private weak var lastBlurFrame: CapturedBackdrop?
    // A frame's scratch output must not be overwritten while the GPU samples it.
    private let inFlight = DispatchSemaphore(value: 1)
    private var didLogError = false
    private var isRegistered = false

    public init(_ config: LiquidGlassConfig = .regular) {
        self.config = config
        super.init(frame: .zero, device: LiquidGlassRenderer.shared?.device)
        isOpaque = false
        layer.isOpaque = false
        clipsToBounds = false
        backgroundColor = .clear
        clearColor = MTLClearColorMake(0, 0, 0, 0)
        colorPixelFormat = .bgra8Unorm
        framebufferOnly = true
        enableSetNeedsDisplay = false
        isPaused = true
        guard let device, let queue = LiquidGlassRenderer.shared?.commandQueue else {
            reportError("Metal device or command queue is missing")
            return
        }
        commandQueue = queue
        backdropCapture = BackdropCapture(device: device, commandQueue: queue, config: config)
        updateShadow()
        isMetalAvailable = true
    }
    required init(coder: NSCoder) { fatalError("Use init(_ config:)") }
    deinit {
        groupCoordinator?.removeChild(id: captureID)
        if isRegistered { LiquidGlassEngine.shared.unregister(self) }
    }

    /// Apply SwiftUI configuration changes without replacing the native view.
    public func updateConfiguration(_ newConfig: LiquidGlassConfig) {
        let captureChanged = config.textureSizeCoefficient != newConfig.textureSizeCoefficient || config.textureScaleCoefficient != newConfig.textureScaleCoefficient
        let shadowChanged = config.shadowOverlay != newConfig.shadowOverlay
            || config.uniforms.cornerRoundnessExponent != newConfig.uniforms.cornerRoundnessExponent
            || config.uniforms.shapeMergeSmoothness != newConfig.uniforms.shapeMergeSmoothness
        config = newConfig
        if captureChanged, let device, let commandQueue {
            backdropCapture?.releaseAll()
            backdropCapture = BackdropCapture(device: device, commandQueue: commandQueue, config: newConfig)
            backdropCapture?.captureFrameRate = max(1, backgroundCaptureFrameRate)
        }
        if shadowChanged { updateShadow() }
    }
    public func captureBackground() {
        forceCaptureRequested = true
        backdropCapture?.invalidate()
        groupCoordinator?.invalidate()
        setNeedsDisplay()
    }
    public func releaseCache() {
        backdropCapture?.releaseAll()
        groupCoordinator?.currentFrame?.scatteredTextures.removeAll()
        groupCoordinator?.invalidate()
        blurPass.releaseResources()
        lastBlurFrame = nil
        forceCaptureRequested = true
        // In-flight commands retain their resources. New captures replace them.
    }
    public func setCaptureInterval(_ interval: Int) {
        backgroundCaptureFrameRate = Double(max(1, targetFrameRate)) / Double(max(1, interval))
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateShadow()
    }
    /// Keep SwiftUI's same-size radius updates and the optical outline in sync.
    func updateCornerRadius(_ radius: CGFloat) {
        guard layer.cornerRadius != radius else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.cornerRadius = radius
        updateShadow()
        CATransaction.commit()
        setNeedsLayout()
    }
    private func updateShadow() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        // Cast behind the Metal surface, never darken it with an overlay ring.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 3.5
        layer.shadowOffset = CGSize(width: 0, height: 1.5)
        layer.shadowOpacity = config.shadowOverlay ? 0.10 : 0
        guard config.shadowOverlay else {
            layer.shadowPath = nil
            return
        }

        // Only the default circular rectangle has an exact UIBezierPath match.
        // Other shapes use the actual Metal alpha, including smooth unions.
        if frames.isEmpty,
           config.uniforms.cornerRoundnessExponent == 2,
           config.uniforms.shapeMergeSmoothness == 0,
           !bounds.isEmpty {
            let radius = max(0, min(layer.cornerRadius, min(bounds.width, bounds.height) / 2))
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        } else {
            layer.shadowPath = nil
        }
    }
    private var windowFrame: CGRect {
        guard let window else { return .zero }
        let displayed = layer.presentation() ?? layer
        return displayed.convert(displayed.bounds, to: window.layer.presentation() ?? window.layer)
    }

    public override func draw(_ rect: CGRect) {
        guard isMetalAvailable, window != nil, bounds.width > 0, bounds.height > 0,
              let renderer = LiquidGlassRenderer.shared,
              inFlight.wait(timeout: .now()) == .success else { return }
        var submitted = false
        defer {
            if !submitted {
                // An encoded blur is not valid until its command was submitted.
                blurPass.invalidate()
                inFlight.signal()
            }
        }
        let globalFrame = windowFrame
        let captured: CapturedBackdrop?
        if let groupCoordinator {
            groupCoordinator.updateChildFrame(id: captureID, frame: globalFrame)
            captured = groupCoordinator.currentFrame
        } else {
            if autoCapture || forceCaptureRequested {
                let previous = backdropCapture?.currentFrame
                backdropCapture?.capture(for: self, contentsScale: contentScaleFactor)
                if let current = backdropCapture?.currentFrame, current !== previous {
                    forceCaptureRequested = false
                }
            }
            captured = backdropCapture?.currentFrame
        }
        guard let captured else { return }
        // Coefficients >= 1 reserve overscan; < 1 is the legacy thumb magnifier.
        let magnification = CGFloat(1 / min(config.textureSizeCoefficient, 1))
        guard let mapping = LiquidGlassSampling.mapping(viewRect: globalFrame, captureRect: captured.captureRect, magnification: magnification),
              let drawable = currentDrawable,
              let pass = currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
        commandBuffer.label = "LiquidGlass blur + optics"
        let pixelsPerPoint = CGFloat(captured.texture.width) / captured.captureRect.width
        // CVMetalTextureCache may return the same texture object for a reused
        // IOSurface. Frame identity, not texture identity, tracks new pixels.
        if lastBlurFrame !== captured { blurPass.invalidate() }
        lastBlurFrame = captured
        let blurKey = Float(config.blurRadius * pixelsPerPoint).bitPattern
        let sharedBlur = groupCoordinator != nil && config.blurRadius > 0
        let scattered: MTLTexture
        var producedSharedBlur: ScatteredBackdropTexture?
        if sharedBlur, let cached = captured.scatteredTextures[blurKey], cached.isUsable {
            scattered = cached.texture
        } else {
            if sharedBlur { captured.scatteredTextures.removeValue(forKey: blurKey) }
            // A group output belongs to this immutable captured frame, never to
            // a reusable per-view scratch slot sampled by other in-flight views.
            let pass = sharedBlur ? LiquidGlassBlurPass() : blurPass
            guard let output = pass.encode(source: captured.texture, radius: config.blurRadius, pixelsPerPoint: pixelsPerPoint, commandBuffer: commandBuffer) else {
                reportError("MPS blur output allocation failed")
                return
            }
            scattered = output
            if sharedBlur {
                producedSharedBlur = ScatteredBackdropTexture(texture: output, producer: commandBuffer)
            }
        }
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        var uniforms = makeUniforms(mapping: mapping)
        encoder.setRenderPipelineState(renderer.pipelineState)
        // Metal copies these bytes into command storage; no shared uniform race.
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<LiquidGlassUniforms>.stride, index: 0)
        encoder.setFragmentTexture(captured.texture, index: 0)
        encoder.setFragmentTexture(scattered, index: 1)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        let semaphore = inFlight
        commandBuffer.addCompletedHandler { [weak self, captured, producedSharedBlur] command in
            withExtendedLifetime(captured) {}
            if command.status == .error {
                // Invalidate immediately on the completion thread, before a
                // different view can reuse this output on the main thread.
                producedSharedBlur?.markFailed()
                let message = command.error?.localizedDescription ?? "unknown error"
                DispatchQueue.main.async {
                    // A consumer failure does not invalidate its producer, and
                    // a delayed producer failure must not remove a replacement.
                    if let producedSharedBlur,
                       captured.scatteredTextures[blurKey] === producedSharedBlur {
                        captured.scatteredTextures.removeValue(forKey: blurKey)
                    }
                    self?.groupCoordinator?.invalidate()
                    self?.blurPass.invalidate()
                    self?.reportError("GPU command failed: \(message)")
                }
            }
            semaphore.signal()
        }
        submitted = true
        commandBuffer.commit()
        if let producedSharedBlur, producedSharedBlur.isUsable {
            captured.scatteredTextures[blurKey] = producedSharedBlur
        }
    }

    private func makeUniforms(mapping: (offset: SIMD2<Float>, scale: SIMD2<Float>)) -> LiquidGlassUniforms {
        var u = config.uniforms
        let scale = drawableSize.width / bounds.width
        u.resolution = SIMD2(Float(drawableSize.width), Float(drawableSize.height))
        u.contentsScale = Float(scale)
        u.cornerRadius = Float(layer.cornerRadius)
        u.uvOffset = mapping.offset
        u.uvScale = mapping.scale
        u.touchPoint = touchPoint.map { SIMD2(Float($0.x), Float($0.y)) } ?? SIMD2(repeating: -1)
        let rectangles = frames.isEmpty ? [CGRect(origin: .zero, size: bounds.size)] : frames
        u.rectangleCount = Int32(min(rectangles.count, LiquidGlassConfig.maxRectangles))
        withUnsafeMutableBytes(of: &u.rectangles) { raw in
            let values = raw.bindMemory(to: SIMD4<Float>.self)
            for i in values.indices {
                if i < rectangles.count {
                    let r = rectangles[i]
                    values[i] = SIMD4(Float(r.minX), Float(r.minY), Float(r.width), Float(r.height))
                } else { values[i] = .zero }
            }
        }
        return u
    }
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            isPaused = true
            releaseCache()
            groupCoordinator?.removeChild(id: captureID)
            if isRegistered {
                isRegistered = false
                LiquidGlassEngine.shared.unregister(self)
            }
        } else {
            if !isRegistered {
                isRegistered = true
                LiquidGlassEngine.shared.register(self)
            }
            isPaused = false
            captureBackground()
        }
    }
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        return target == self ? nil : target
    }
    private func reportError(_ message: String) {
        guard !didLogError else { return }
        didLogError = true
        NSLog("[LiquidGlassEffect] %@", message)
    }
}
