//
//  ZeroCopyBridge.swift
//  LiquidGlassEffect
//

import UIKit
import Metal
import CoreVideo

/// Shared blur output with the status of the command that produced it.
/// The command reference is weak: completion handlers retain the captured frame,
/// whose cache retains this entry, so a strong producer would create a cycle.
final class ScatteredBackdropTexture {
    let texture: MTLTexture
    private weak var producer: MTLCommandBuffer?
    private let lock = NSLock()
    private var failed = false

    init(texture: MTLTexture, producer: MTLCommandBuffer) {
        self.texture = texture
        self.producer = producer
    }

    var isUsable: Bool {
        lock.lock()
        defer { lock.unlock() }
        // A producer can become .error before its completion callback has run.
        // After the producer is released, the persistent flag preserves failure.
        return !failed && producer?.status != .error
    }

    func markFailed() {
        lock.lock()
        failed = true
        lock.unlock()
    }
}

/// A captured image and its coordinate domain are one immutable value.
/// Keep this object alive until every Metal command sampling it has completed.
final class CapturedBackdrop {
    let texture: MTLTexture
    let captureRect: CGRect
    // Main-thread cache, published only after the producing render command is
    // committed to LiquidGlassRenderer's shared ordered command queue.
    var scatteredTextures: [UInt32: ScatteredBackdropTexture] = [:]
    private let pixelBuffer: CVPixelBuffer
    private let cvTexture: CVMetalTexture

    fileprivate init(texture: MTLTexture, captureRect: CGRect,
                     pixelBuffer: CVPixelBuffer, cvTexture: CVMetalTexture) {
        self.texture = texture
        self.captureRect = captureRect
        self.pixelBuffer = pixelBuffer
        self.cvTexture = cvTexture
    }
}

/// CPU/GPU image sharing. Each capture leases a distinct pool buffer while older
/// captures are in flight, instead of overwriting a two-slot IOSurface ring.
public final class ZeroCopyBridge {
    public let device: MTLDevice
    private var textureCache: CVMetalTextureCache?
    private var pixelBufferPool: CVPixelBufferPool?
    private var bufferSize = CGSize.zero
    private let copyQueue: MTLCommandQueue?
    private var capturesSinceCacheFlush = 0

    public init(device: MTLDevice) {
        self.device = device
        self.copyQueue = device.makeCommandQueue()
        let status = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        if status != kCVReturnSuccess {
            print("[LiquidGlassEffect] Texture cache creation failed: \(status)")
        }
    }

    public func setupBuffer(width: Int, height: Int) {
        guard width > 0, height > 0 else {
            releaseBuffers()
            return
        }
        let requestedSize = CGSize(width: width, height: height)
        guard requestedSize != bufferSize || pixelBufferPool == nil else { return }
        let attributes: [String: Any] = [
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as [String: Any]
        ]
        var pool: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pool)
        guard status == kCVReturnSuccess, let pool else {
            print("[LiquidGlassEffect] Pixel buffer pool creation failed: \(status)")
            releaseBuffers()
            return
        }
        pixelBufferPool = pool
        bufferSize = requestedSize
        if let textureCache { CVMetalTextureCacheFlush(textureCache, 0) }
    }

    func releaseBuffers() {
        pixelBufferPool = nil
        bufferSize = .zero
        if let textureCache { CVMetalTextureCacheFlush(textureCache, 0) }
    }

    /// The context is top-left/y-down, in pixels. Callers supply the point scale.
    func renderFrame(captureRect: CGRect, actions: (CGContext) -> Void) -> CapturedBackdrop? {
        guard let pool = pixelBufferPool, let cache = textureCache else { return nil }
        capturesSinceCacheFlush += 1
        if capturesSinceCacheFlush >= 30 {
            // CoreVideo requires periodic cache housekeeping. Live frame leases
            // retain their CVMetalTexture, so flushing never recycles GPU input.
            CVMetalTextureCacheFlush(cache, 0)
            capturesSinceCacheFlush = 0
        }
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else {
            print("[LiquidGlassEffect] Pixel buffer lease failed: \(status)")
            return nil
        }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTexture: CVMetalTexture?
        let textureStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, cache, pixelBuffer,
            [kCVMetalTextureUsage: MTLTextureUsage.shaderRead.rawValue] as CFDictionary,
            .bgra8Unorm, width, height, 0, &cvTexture
        )
        guard textureStatus == kCVReturnSuccess,
              let cvTexture, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("[LiquidGlassEffect] Metal texture creation failed: \(textureStatus)")
            return nil
        }
        let lockStatus = CVPixelBufferLockBaseAddress(pixelBuffer, [])
        guard lockStatus == kCVReturnSuccess else { return nil }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer), width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        // Clear reused storage: transparent content must never retain an old frame.
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        actions(context)
        context.flush()
        return CapturedBackdrop(texture: texture, captureRect: captureRect,
                                pixelBuffer: pixelBuffer, cvTexture: cvTexture)
    }

    /// Compatibility API. A bare MTLTexture cannot convey the CV buffer lease,
    /// so copy into an owned Metal allocation before releasing that lease.
    /// The rendering path uses renderFrame directly and remains zero-copy.
    public func render(actions: (CGContext) -> Void) -> MTLTexture? {
        guard let frame = renderFrame(captureRect: CGRect(origin: .zero, size: bufferSize), actions: actions),
              let commandBuffer = copyQueue?.makeCommandBuffer() else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: frame.texture.pixelFormat, width: frame.texture.width,
            height: frame.texture.height, mipmapped: false
        )
        descriptor.usage = .shaderRead
        guard let destination = device.makeTexture(descriptor: descriptor),
              let encoder = commandBuffer.makeBlitCommandEncoder() else { return nil }
        encoder.copy(from: frame.texture, to: destination)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        withExtendedLifetime(frame) {}
        guard commandBuffer.status == .completed else {
            print("[LiquidGlassEffect] Compatibility texture copy failed: \(String(describing: commandBuffer.error))")
            return nil
        }
        return destination
    }
}
