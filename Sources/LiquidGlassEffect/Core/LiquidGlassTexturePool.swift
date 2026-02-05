//
//  LiquidGlassTexturePool.swift
//  LiquidGlassEffect
//
//  全局纹理池 - 管理和复用 MTLTexture，减少显存波动
//

import Metal
import UIKit

/// 纹理描述符的哈希键
private struct TextureKey: Hashable {
    let width: Int
    let height: Int
    let pixelFormat: MTLPixelFormat
    let usageRawValue: UInt
    
    init(descriptor: MTLTextureDescriptor) {
        self.width = descriptor.width
        self.height = descriptor.height
        self.pixelFormat = descriptor.pixelFormat
        self.usageRawValue = descriptor.usage.rawValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(pixelFormat)
        hasher.combine(usageRawValue)
    }
    
    static func == (lhs: TextureKey, rhs: TextureKey) -> Bool {
        return lhs.width == rhs.width &&
               lhs.height == rhs.height &&
               lhs.pixelFormat == rhs.pixelFormat &&
               lhs.usageRawValue == rhs.usageRawValue
    }
}

/// 全局纹理池
public final class LiquidGlassTexturePool {
    
    public static let shared = LiquidGlassTexturePool()
    
    private let device: MTLDevice?
    private let lock = NSLock()
    
    // 纹理缓存: Key -> [Texture]
    private var pool: [TextureKey: [MTLTexture]] = [:]
    
    // 活跃纹理计数 (调试用)
    private var activeCount: Int = 0
    
    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// 从池中获取一个纹理，如果没有则创建
    public func checkout(descriptor: MTLTextureDescriptor) -> MTLTexture? {
        guard let device = device else { return nil }
        
        let key = TextureKey(descriptor: descriptor)
        
        lock.lock()
        defer { lock.unlock() }
        
        // 尝试从缓存获取
        if var textures = pool[key], !textures.isEmpty {
            let texture = textures.removeLast()
            pool[key] = textures
            activeCount += 1
            return texture
        }
        
        // 创建新纹理
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        activeCount += 1
        return texture
    }
    
    /// 归还纹理到池中
    public func checkin(_ texture: MTLTexture) {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = texture.width
        descriptor.height = texture.height
        descriptor.pixelFormat = texture.pixelFormat
        descriptor.usage = texture.usage
        // 注意：MTLTextureDescriptor 还有其他属性如 mipmapLevel，暂简化处理
        
        let key = TextureKey(descriptor: descriptor)
        
        lock.lock()
        defer { lock.unlock() }
        
        var textures = pool[key] ?? []
        textures.append(texture)
        pool[key] = textures
        activeCount -= 1
    }
    
    /// 清空所有缓存
    public func purge() {
        lock.lock()
        defer { lock.unlock() }
        pool.removeAll()
        print("[LiquidGlassTexturePool] Purged all cached textures.")
    }
    
    @objc private func handleMemoryWarning() {
        purge()
    }
    
    /// 获取调试信息
    public var debugDescription: String {
        lock.lock()
        defer { lock.unlock() }
        let cachedCount = pool.values.reduce(0) { $0 + $1.count }
        return "Active: \(activeCount), Cached: \(cachedCount)"
    }
}
