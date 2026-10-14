//
//  BackdropCapture.swift
//  LiquidGlassEffect
//

import UIKit
import Metal

/// Captures only the compositor content behind the glass. Captured resources
/// are CV pool leases, never allocations owned by LiquidGlassTexturePool.
final class BackdropCapture {
    var captureFrameRate: Double = 30
    private var lastCaptureTime: CFTimeInterval = 0
    private var lastCaptureRect: CGRect = .null
    private let backdropView = BackdropView()
    private let zeroCopyBridge: ZeroCopyBridge
    private let config: LiquidGlassConfig
    private(set) var currentFrame: CapturedBackdrop?
    private var didReportCaptureFailure = false

    // Retained for internal source compatibility. Freezing is explicit at the
    // view's autoCapture boundary, not guessed from the glass position.
    var isFrozen: Bool { false }
    var currentTexture: MTLTexture? { currentFrame?.texture }

    init(device: MTLDevice, commandQueue: MTLCommandQueue, config: LiquidGlassConfig) {
        self.config = config
        zeroCopyBridge = ZeroCopyBridge(device: device)
    }

    deinit {
        backdropView.removeFromSuperview()
    }

    func setupBuffer(width: Int, height: Int) {
        zeroCopyBridge.setupBuffer(width: width, height: height)
    }

    @discardableResult
    func capture(for view: UIView, contentsScale: CGFloat) -> Bool {
        guard let superview = view.superview, let window = view.window,
              view.bounds.width > 0, view.bounds.height > 0 else { return false }
        let sourceLayer = view.layer.presentation() ?? view.layer
        let parentLayer = superview.layer.presentation() ?? superview.layer
        let windowLayer = window.layer.presentation() ?? window.layer
        let glassRect = sourceLayer.convert(sourceLayer.bounds, to: parentLayer)
        let coefficient = CGFloat(config.textureSizeCoefficient)
        let captureSize = CGSize(width: glassRect.width * coefficient, height: glassRect.height * coefficient)
        let localRect = CGRect(x: glassRect.midX - captureSize.width / 2,
                               y: glassRect.midY - captureSize.height / 2,
                               width: captureSize.width, height: captureSize.height)
        let captureRect = parentLayer.convert(localRect, to: windowLayer)
        guard captureRect.width.isFinite, captureRect.height.isFinite,
              captureRect.width > 0, captureRect.height > 0 else { return false }
        let changed = captureRect != lastCaptureRect
        let now = CACurrentMediaTime()
        let interval = 1 / max(captureFrameRate, 1)
        guard changed || currentFrame == nil || now - lastCaptureTime >= interval else { return false }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if backdropView.superview !== superview {
            superview.insertSubview(backdropView, belowSubview: view)
        }
        backdropView.frame = localRect
        CATransaction.commit()

        let pixelScale = contentsScale * CGFloat(config.textureScaleCoefficient)
        guard pixelScale.isFinite, pixelScale > 0 else { return false }
        let width = max(1, Int(ceil(captureSize.width * pixelScale)))
        let height = max(1, Int(ceil(captureSize.height * pixelScale)))
        zeroCopyBridge.setupBuffer(width: width, height: height)
        var didDraw = false
        let frame = zeroCopyBridge.renderFrame(captureRect: captureRect) { context in
            context.scaleBy(x: CGFloat(width) / captureSize.width,
                            y: CGFloat(height) / captureSize.height)
            UIGraphicsPushContext(context)
            didDraw = self.backdropView.drawHierarchy(in: self.backdropView.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        }
        guard didDraw, let frame else {
            if !didReportCaptureFailure {
                print("[LiquidGlassEffect] Backdrop capture failed (drawHierarchy=\(didDraw), size=\(captureSize)). No new frame was published.")
                didReportCaptureFailure = true
            }
            return false
        }
        currentFrame = frame
        lastCaptureRect = captureRect
        lastCaptureTime = now
        return changed
    }

    func invalidate() {
        // Keep the last valid image until a replacement is complete.
        lastCaptureTime = 0
        lastCaptureRect = .null
    }

    func releaseAll() {
        backdropView.removeFromSuperview()
        currentFrame = nil
        zeroCopyBridge.releaseBuffers()
        invalidate()
    }
}
