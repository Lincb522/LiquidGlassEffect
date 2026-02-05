//
//  LiquidGlassTexturePool.swift
//  LiquidGlassEffect
//
//  全局纹理池 - 管理和复用 MTLTexture，减少显存波动
//

import Metal
import UIKit

// MARK: - Texture Key

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
    
    init(texture: MTLTexture) {
        self.width = texture.width
        self.height = texture.height
        self.pixelFormat = texture.pixelFormat
        self.usageRawValue = texture.usage.rawValue
    }
}

// MARK: - Texture Pool

/// 全局纹理池
///
/// 管理 Metal 纹理的创建和复用，减少频繁的显存分配。
/// 使用 LRU 策略自动清理长时间未使用的纹理。
public final class LiquidGlassTexturePool {
    
    // MARK: - Singleton
    
    public static let shared = LiquidGlassTexturePool()
    
    // MARK: - Configuration
    
    /// 每种尺寸最大缓存数量
    public var maxCachedPerSize: Int = 4
    
    /// 最大总缓存数量
    public var maxTotalCached: Int = 32
    
    // MARK: - Private Properties
    
    private let device: MTLDevice?
    private let lock = NSLock()
    private var pool: [TextureKey: [MTLTexture]] = [:]
    private var activeCount: Int = 0
    private var totalCachedCount: Int = 0
    
    // MARK: - Init
    
    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API
    
    /// 从池中获取纹理
    ///
    /// 如果池中有匹配的纹理则复用，否则创建新纹理。
    /// - Parameter descriptor: 纹理描述符
    /// - Returns: Metal 纹理，如果创建失败则返回 nil
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
            totalCachedCount -= 1
            return texture
        }
        
        // 创建新纹理
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        activeCount += 1
        return texture
    }
    
    /// 归还纹理到池中
    ///
    /// - Parameter texture: 要归还的纹理
    public func checkin(_ texture: MTLTexture) {
        let key = TextureKey(texture: texture)
        
        lock.lock()
        defer { lock.unlock() }
        
        activeCount -= 1
        
        // 检查是否超过缓存限制
        var textures = pool[key] ?? []
        if textures.count >= maxCachedPerSize || totalCachedCount >= maxTotalCached {
            // 超过限制，直接丢弃（让 ARC 释放）
            return
        }
        
        textures.append(texture)
        pool[key] = textures
        totalCachedCount += 1
    }
    
    /// 清空所有缓存
    public func purge() {
        lock.lock()
        defer { lock.unlock() }
        
        pool.removeAll()
        totalCachedCount = 0
        
        #if DEBUG
        print("[LiquidGlassTexturePool] Purged all cached textures")
        #endif
    }
    
    /// 清理指定尺寸的缓存
    public func purge(width: Int, height: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        let keysToRemove = pool.keys.filter { $0.width == width && $0.height == height }
        for key in keysToRemove {
            if let textures = pool.removeValue(forKey: key) {
                totalCachedCount -= textures.count
            }
        }
    }
    
    // MARK: - Statistics
    
    /// 当前活跃纹理数量
    public var activeTextureCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeCount
    }
    
    /// 当前缓存纹理数量
    public var cachedTextureCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return totalCachedCount
    }
    
    /// 调试信息
    public var debugDescription: String {
        lock.lock()
        defer { lock.unlock() }
        return "Active: \(activeCount), Cached: \(totalCachedCount), Pools: \(pool.count)"
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        purge()
    }
}
