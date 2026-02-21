//
//  ZeroCopyBridge.swift
//  LiquidGlassEffect
//
//  零拷贝 CPU-GPU 纹理桥接
//

import UIKit
import Metal
import CoreVideo

/// 零拷贝纹理桥接，用于高效的 CPU-GPU 数据共享
public final class ZeroCopyBridge {
    
    public let device: MTLDevice
    private var textureCache: CVMetalTextureCache?
    private var pixelBuffer: CVPixelBuffer?
    private var cvTexture: CVMetalTexture?
    
    public init(device: MTLDevice) {
        self.device = device
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
    }
    
    /// 设置像素缓冲区尺寸
    public func setupBuffer(width: Int, height: Int) {
        guard width > 0, height > 0 else { return }
        
        let attrs = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [String: Any]
        ] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard let buffer = pixelBuffer, let cache = textureCache else { return }
        
        var texture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, cache, buffer, nil, .bgra8Unorm, width, height, 0, &texture)
        self.cvTexture = texture
    }
    
    /// 渲染内容到纹理
    public func render(actions: (CGContext) -> Void) -> MTLTexture? {
        guard let buffer = pixelBuffer, let cache = textureCache else { return nil }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            CVMetalTextureCacheFlush(cache, 0)
        }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        
        actions(context)
        
        return cvTexture.flatMap { CVMetalTextureGetTexture($0) }
    }
}
