//
//  LiquidGlassGroup.swift
//  LiquidGlassEffect
//

import SwiftUI
import MetalKit

/// One immutable background snapshot shared by the group's glass surfaces.
public final class LiquidGlassGroupCoordinator: ObservableObject {
    private(set) var currentFrame: CapturedBackdrop?
    var sharedTexture: MTLTexture? { currentFrame?.texture }
    var captureRect: CGRect { currentFrame?.captureRect ?? .zero }
    private var childFrames: [UUID: CGRect] = [:]
    var onCaptureNeeded: (() -> Void)?

    public init() {}

    func updateChildFrame(id: UUID, frame: CGRect) {
        guard !frame.isNull, frame.width > 0, frame.height > 0,
              frame.origin.x.isFinite, frame.origin.y.isFinite,
              frame.width.isFinite, frame.height.isFinite else { return }
        guard childFrames[id] != frame else { return }
        childFrames[id] = frame
        onCaptureNeeded?()
    }

    func removeChild(id: UUID) {
        guard childFrames.removeValue(forKey: id) != nil else { return }
        onCaptureNeeded?()
    }

    var childBounds: CGRect {
        childFrames.values.reduce(CGRect.null) { $0.union($1) }
    }

    func updateFrame(_ frame: CapturedBackdrop) {
        // No @Published texture: a capture does not rebuild the SwiftUI tree.
        currentFrame = frame
    }

    func invalidate() { onCaptureNeeded?() }
    func releaseFrame() { currentFrame = nil }
}

public struct LiquidGlassGroup<Content: View>: View {
    let content: Content
    @StateObject private var coordinator = LiquidGlassGroupCoordinator()

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .environment(\.liquidGlassGroupCoordinator, coordinator)
            .background(LiquidGlassGroupBackdrop(coordinator: coordinator))
    }
}

private struct LiquidGlassGroupBackdrop: UIViewRepresentable {
    let coordinator: LiquidGlassGroupCoordinator

    func makeUIView(context: Context) -> LiquidGlassGroupBackdropView {
        let view = LiquidGlassGroupBackdropView()
        view.coordinator = coordinator
        return view
    }

    func updateUIView(_ uiView: LiquidGlassGroupBackdropView, context: Context) {
        uiView.coordinator = coordinator
    }

    static func dismantleUIView(_ uiView: LiquidGlassGroupBackdropView, coordinator: ()) {
        uiView.stopCaptureLoop()
    }
}

final class LiquidGlassGroupBackdropView: UIView {
    weak var coordinator: LiquidGlassGroupCoordinator? {
        didSet {
            guard coordinator !== oldValue else { return }
            oldValue?.onCaptureNeeded = nil
            coordinator?.onCaptureNeeded = { [weak self] in self?.setNeedsLayout() }
        }
    }
    private let backdropView = BackdropView()
    private var zeroCopyBridge: ZeroCopyBridge?
    private var displayLink: CADisplayLink?
    private var didReportCaptureFailure = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = false
        // As a SwiftUI background, this sample layer is below the entire group,
        // so neither the group's glass nor its labels feed back into the image.
        addSubview(backdropView)
        if let device = LiquidGlassRenderer.shared?.device {
            zeroCopyBridge = ZeroCopyBridge(device: device)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    deinit {
        displayLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startCaptureLoop() }
        else {
            stopCaptureLoop()
            coordinator?.releaseFrame()
            zeroCopyBridge?.releaseBuffers()
        }
    }

    func capture() {
        guard let window, let bridge = zeroCopyBridge, let coordinator,
              bounds.width > 0, bounds.height > 0 else { return }
        let sourceLayer = layer.presentation() ?? layer
        let windowLayer = window.layer.presentation() ?? window.layer
        let hostRect = sourceLayer.convert(bounds, to: windowLayer)
        let children = coordinator.childBounds
        let contentRect = children.isNull ? hostRect : hostRect.union(children)
        // Optical overscan is an actual spatial margin, not a texture zoom.
        let margin = max(16, min(contentRect.width, contentRect.height) * 0.1)
        let captureRect = contentRect.insetBy(dx: -margin, dy: -margin)
        guard captureRect.width.isFinite, captureRect.height.isFinite,
              captureRect.width > 0, captureRect.height > 0 else { return }
        let localRect = windowLayer.convert(captureRect, to: sourceLayer)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdropView.frame = localRect
        CATransaction.commit()
        let scale = window.screen.scale
        let width = max(1, Int(ceil(localRect.width * scale)))
        let height = max(1, Int(ceil(localRect.height * scale)))
        bridge.setupBuffer(width: width, height: height)
        var didDraw = false
        let frame = bridge.renderFrame(captureRect: captureRect) { context in
            context.scaleBy(x: CGFloat(width) / localRect.width,
                            y: CGFloat(height) / localRect.height)
            UIGraphicsPushContext(context)
            didDraw = self.backdropView.drawHierarchy(in: self.backdropView.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        }
        guard didDraw, let frame else {
            if !didReportCaptureFailure {
                print("[LiquidGlassEffect] Group backdrop capture failed (drawHierarchy=\(didDraw), size=\(localRect.size)). No new frame was published.")
                didReportCaptureFailure = true
            }
            return
        }
        coordinator.updateFrame(frame)
    }

    private func startCaptureLoop() {
        stopCaptureLoop()
        let target = GroupDisplayLinkTarget(view: self)
        let link = CADisplayLink(target: target, selector: #selector(GroupDisplayLinkTarget.tick))
        link.preferredFramesPerSecond = 30
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopCaptureLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func applicationDidEnterBackground() { stopCaptureLoop() }
    @objc private func applicationDidBecomeActive() {
        if window != nil { startCaptureLoop() }
    }

    fileprivate func displayLinkTick() {
        // Recapture even when geometry is static: the background can animate.
        capture()
    }
}

private final class GroupDisplayLinkTarget: NSObject {
    weak var view: LiquidGlassGroupBackdropView?
    init(view: LiquidGlassGroupBackdropView) { self.view = view }
    @objc func tick() { view?.displayLinkTick() }
}
