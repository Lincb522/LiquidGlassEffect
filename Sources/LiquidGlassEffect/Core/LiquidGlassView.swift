//
//  LiquidGlassView.swift
//  LiquidGlassEffect
//
//  液态玻璃效果 MTKView（高性能版）
//  Credits: https://github.com/DnV1eX/LiquidGlassKit
//

import UIKit
import MetalKit
import MetalPerformanceShaders

/// 液态玻璃效果视图
public final class LiquidGlassView: MTKView {
    
    public let config: LiquidGlassConfig
    
    private var commandQueue: MTLCommandQueue?
    private var uniformsBuffer: MTLBuffer?
    private var zeroCopyBridge: ZeroCopyBridge?
    private var backgroundTexture: MTLTexture?
    private let backdropView = BackdropView()
    private weak var shadowView: ShadowView?
    
    // MARK: - 性能优化
    
    /// 帧率限制
    public var targetFrameRate: Int = 60 {
        didSet { preferredFramesPerSecond = targetFrameRate }
    }
    
    /// 背景捕获帧率限制（默认 30fps，降低 CPU 占用）
    public var backgroundCaptureFrameRate: Double = 30.0
    
    /// 上次捕获背景的时间
    private var lastCaptureTime: CFTimeInterval = 0
    
    /// 是否自动捕获背景
    public var autoCapture: Bool = true
    
    /// 上次布局的尺寸
    private var lastLayoutSize: CGSize = .zero
    
    /// 触摸点
    public var touchPoint: CGPoint? = nil
    
    /// 玻璃矩形区域
    public var frames: [CGRect] = []
    
    /// Metal 是否可用
    public private(set) var isMetalAvailable: Bool = false
    
    /// 是否已注册到引擎
    private var isRegisteredToEngine: Bool = false
    
    /// 双缓冲纹理 - 避免黑框
    private var textureA: MTLTexture?
    private var textureB: MTLTexture?
    private var useTextureA: Bool = true
    
    // MARK: - Init
    
    public init(_ config: LiquidGlassConfig = .regular) {
        self.config = config
        super.init(frame: .zero, device: LiquidGlassRenderer.shared?.device)
        
        if config.shadowOverlay {
            let shadow = ShadowView()
            addSubview(shadow)
            self.shadowView = shadow
        }
        
        setupMetal()
        registerToEngine()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    deinit {
        unregisterFromEngine()
    }
    
    private func setupMetal() {
        guard let device = device,
              let queue = device.makeCommandQueue(),
              let buffer = device.makeBuffer(length: MemoryLayout<LiquidGlassUniforms>.stride, options: .storageModeShared)
        else {
            print("[LiquidGlassEffect] Metal device not available")
            isMetalAvailable = false
            return
        }
        
        commandQueue = queue
        uniformsBuffer = buffer
        zeroCopyBridge = ZeroCopyBridge(device: device)
        
        // 优化设置
        isOpaque = false
        layer.isOpaque = false
        backgroundColor = .clear
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        isPaused = false
        preferredFramesPerSecond = 60
        enableSetNeedsDisplay = false
        presentsWithTransaction = false
        framebufferOnly = false  // 允许读取 framebuffer
        
        isMetalAvailable = true
    }
    
    // MARK: - Engine Integration
    
    private func registerToEngine() {
        guard !isRegisteredToEngine else { return }
        LiquidGlassEngine.shared.register(self)
        isRegisteredToEngine = true
    }
    
    private func unregisterFromEngine() {
        guard isRegisteredToEngine else { return }
        LiquidGlassEngine.shared.unregister(self)
        isRegisteredToEngine = false
    }
    
    // MARK: - Public API
    
    public func captureBackground() {
        textureA = nil
        textureB = nil
    }
    
    public func setCaptureInterval(_ interval: Int) {
        // 兼容旧 API
    }
    
    // MARK: - Background Capture
    
    private func captureBackdrop() {
        guard isMetalAvailable,
              let superview = superview,
              let zeroCopyBridge = zeroCopyBridge else { return }
        
        let sizeCoeff = config.textureSizeCoefficient
        let scaleCoeff = layer.contentsScale * config.textureScaleCoefficient
        
        // 使用 presentation layer 获取实时位置
        let currentLayer = layer.presentation() ?? layer
        let frameInSuperview = currentLayer.convert(currentLayer.bounds, to: superview.layer)
        
        // 使用原始 LiquidGlassKit 的捕获方式
        let captureSize = CGSize(
            width: frameInSuperview.width * sizeCoeff,
            height: frameInSuperview.height * sizeCoeff
        )
        let captureOrigin = CGPoint(
            x: frameInSuperview.midX - captureSize.width / 2,
            y: frameInSuperview.midY - captureSize.height / 2
        )
        
        backdropView.frame = CGRect(origin: captureOrigin, size: captureSize)
        
        if backdropView.superview !== superview {
            superview.insertSubview(backdropView, belowSubview: self)
        }
        
        // 使用 drawHierarchy 捕获
        let newTexture = zeroCopyBridge.render { context in
            context.scaleBy(x: scaleCoeff, y: scaleCoeff)
            UIGraphicsPushContext(context)
            self.backdropView.drawHierarchy(in: self.backdropView.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        }
        
        // 双缓冲：交替使用两个纹理槽
        if let texture = newTexture {
            if useTextureA {
                textureA = texture
            } else {
                textureB = texture
            }
            useTextureA.toggle()
            
            // 异步模糊
            if config.blurRadius > 0 {
                applyBlurAsync(to: texture)
            }
        }
    }
    
    /// 获取当前可用的纹理（双缓冲）
    private var currentTexture: MTLTexture? {
        // 优先使用最新的纹理，如果没有则使用备用
        if useTextureA {
            return textureB ?? textureA
        } else {
            return textureA ?? textureB
        }
    }
    
    private func applyBlurAsync(to texture: MTLTexture) {
        guard let device = device,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        var tex = texture
        let sigma = Float(config.blurRadius * Double(layer.contentsScale))
        let blur = MPSImageGaussianBlur(device: device, sigma: sigma)
        blur.edgeMode = .clamp
        blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &tex, fallbackCopyAllocator: nil)
        commandBuffer.commit()
    }
    
    private func updateUniforms() {
        guard let uniformsBuffer = uniformsBuffer else { return }
        
        var uniforms = config.uniforms
        let scale = layer.contentsScale
        
        uniforms.resolution = .init(x: Float(bounds.width * scale), y: Float(bounds.height * scale))
        uniforms.contentsScale = Float(scale)
        uniforms.shapeMergeSmoothness = 0.2
        uniforms.cornerRadius = Float(layer.cornerRadius)
        
        if let touchPoint = touchPoint {
            uniforms.touchPoint = .init(x: Float(touchPoint.x), y: Float(touchPoint.y))
        }
        
        let effectiveFrames = frames.isEmpty ? [bounds] : frames
        uniforms.rectangleCount = Int32(min(effectiveFrames.count, LiquidGlassConfig.maxRectangles))
        
        let ptr = uniformsBuffer.contents().assumingMemoryBound(to: LiquidGlassUniforms.self)
        ptr.pointee = uniforms
        
        withUnsafeMutablePointer(to: &ptr.pointee.rectangles) { rectPtr in
            let base = UnsafeMutableRawPointer(rectPtr).assumingMemoryBound(to: SIMD4<Float>.self)
            for i in 0..<LiquidGlassConfig.maxRectangles {
                if i < effectiveFrames.count {
                    let frame = effectiveFrames[i]
                    base[i] = SIMD4<Float>(Float(frame.origin.x), Float(frame.origin.y), Float(frame.width), Float(frame.height))
                } else {
                    base[i] = .zero
                }
            }
        }
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard isMetalAvailable else { return }
        
        let currentSize = bounds.size
        guard currentSize != lastLayoutSize, currentSize.width > 0, currentSize.height > 0 else { return }
        lastLayoutSize = currentSize
        
        updateUniforms()
        
        // 扩大 buffer
        let scale = layer.contentsScale * CGFloat(config.textureSizeCoefficient * config.textureScaleCoefficient)
        zeroCopyBridge?.setupBuffer(
            width: Int(bounds.width * scale),
            height: Int(bounds.height * scale)
        )
        shadowView?.frame = bounds
    }
    
    // MARK: - Draw
    
    public override func draw(_ rect: CGRect) {
        guard isMetalAvailable, let renderer = LiquidGlassRenderer.shared else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // 捕获背景（带节流控制）
        if autoCapture {
            let currentTime = CACurrentMediaTime()
            let interval = 1.0 / backgroundCaptureFrameRate
            
            if currentTime - lastCaptureTime >= interval {
                captureBackdrop()
                lastCaptureTime = currentTime
            }
        }
        
        // 使用双缓冲纹理
        let textureToUse = currentTexture
        
        guard let drawable = currentDrawable,
              let renderPassDesc = currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
        
        // 透明清除色
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDesc.colorAttachments[0].loadAction = .clear
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }
        
        // 有纹理才渲染
        if let texture = textureToUse {
            encoder.setRenderPipelineState(renderer.pipelineState)
            encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Memory Management
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            isPaused = true
        } else {
            isPaused = false
            textureA = nil
            textureB = nil
        }
    }
    
    public func releaseCache() {
        textureA = nil
        textureB = nil
    }
}
