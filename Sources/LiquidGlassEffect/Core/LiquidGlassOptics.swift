import UIKit
import Metal
import MetalPerformanceShaders

/// One coordinate contract for both independent and grouped capture.
/// Capture extents are window points; shader UVs are top-left normalized values.
enum LiquidGlassSampling {
    static func mapping(viewRect: CGRect, captureRect: CGRect, magnification: CGFloat = 1) -> (offset: SIMD2<Float>, scale: SIMD2<Float>)? {
        guard captureRect.width > 0, captureRect.height > 0,
              viewRect.width > 0, viewRect.height > 0,
              magnification.isFinite, magnification > 0 else { return nil }
        let sampleSize = CGSize(width: viewRect.width / magnification, height: viewRect.height / magnification)
        let origin = CGPoint(x: viewRect.midX - sampleSize.width / 2, y: viewRect.midY - sampleSize.height / 2)
        let offset = SIMD2<Float>(Float((origin.x - captureRect.minX) / captureRect.width), Float((origin.y - captureRect.minY) / captureRect.height))
        let scale = SIMD2<Float>(Float(sampleSize.width / captureRect.width), Float(sampleSize.height / captureRect.height))
        guard offset.x.isFinite, offset.y.isFinite, scale.x.isFinite, scale.y.isFinite else { return nil }
        return (offset, scale)
    }
}

/// MPS owns the blur implementation. Out-of-place encoding in the SAME command
/// buffer as sampling guarantees that the shader never sees partially blurred data.
final class LiquidGlassBlurPass {
    private var output: MTLTexture?
    private var kernel: MPSImageGaussianBlur?
    private var lastSigma: Float = -1
    private var source: MTLTexture?

    func encode(source: MTLTexture, radius: Double, pixelsPerPoint: CGFloat, commandBuffer: MTLCommandBuffer) -> MTLTexture? {
        guard radius > 0 else { return source }
        let sigma = Float(radius * pixelsPerPoint)
        guard sigma.isFinite, sigma > 0 else { return nil }
        if kernel == nil || sigma != lastSigma {
            kernel = MPSImageGaussianBlur(device: source.device, sigma: sigma)
            kernel?.edgeMode = .clamp
            lastSigma = sigma
            self.source = nil
        }
        if output?.width != source.width || output?.height != source.height || output?.pixelFormat != source.pixelFormat {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: source.pixelFormat, width: source.width, height: source.height, mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .private
            output = source.device.makeTexture(descriptor: descriptor)
            output?.label = "LiquidGlass scattered backdrop"
            self.source = nil
        }
        guard let output, let kernel else { return nil }
        if self.source !== source {
            kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: output)
            self.source = source
        }
        return output
    }
    func invalidate() { source = nil }
    func releaseResources() {
        source = nil
        output = nil
        kernel = nil
        lastSigma = -1
    }
}
