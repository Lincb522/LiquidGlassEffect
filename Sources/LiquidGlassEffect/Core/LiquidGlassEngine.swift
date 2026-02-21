//
//  LiquidGlassEngine.swift
//  LiquidGlassEffect
//
//  性能优化引擎 - 统一管理所有液态玻璃视图的渲染
//

import UIKit

// MARK: - Performance Mode

/// 性能模式
public enum LiquidGlassPerformanceMode: String, CaseIterable {
    /// 高质量（60fps）
    case quality
    /// 平衡（60fps，适度优化）
    case balanced
    /// 省电（30fps）
    case efficiency
    /// 静态（仅在需要时渲染）
    case `static`
    
    var frameRate: Int {
        switch self {
        case .quality: return 60
        case .balanced: return 60
        case .efficiency: return 30
        case .static: return 15
        }
    }
    
    var backgroundCaptureRate: Double {
        switch self {
        case .quality: return 60.0
        case .balanced: return 30.0
        case .efficiency: return 20.0
        case .static: return 10.0
        }
    }
}

// MARK: - Engine

/// 液态玻璃性能优化引擎
///
/// 单例模式，统一管理所有液态玻璃视图的生命周期和性能。
/// 支持自适应性能调节、内存警告响应、应用状态管理。
public final class LiquidGlassEngine {
    
    // MARK: - Singleton
    
    public static let shared = LiquidGlassEngine()
    
    // MARK: - Public Properties
    
    /// 当前性能模式
    public var performanceMode: LiquidGlassPerformanceMode = .quality {
        didSet {
            guard performanceMode != oldValue else { return }
            applyPerformanceMode()
        }
    }
    
    /// 全局帧率限制
    public private(set) var globalFrameRate: Int = 60
    
    /// 是否启用自适应性能
    public var adaptivePerformance: Bool = true
    
    /// 最大同时渲染的视图数量
    public var maxConcurrentViews: Int = 10
    
    /// 内存警告时自动降级
    public var autoDowngradeOnMemoryWarning: Bool = true
    
    // MARK: - Private Properties
    
    private var registeredViews: NSHashTable<LiquidGlassView> = .weakObjects()
    private let lock = NSLock()
    
    // MARK: - Init
    
    private init() {
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Registration
    
    /// 注册视图
    public func register(_ view: LiquidGlassView) {
        lock.lock()
        registeredViews.add(view)
        let count = registeredViews.count
        lock.unlock()
        
        applySettingsToView(view)
        
        // 自适应降级
        if adaptivePerformance && count > maxConcurrentViews {
            downgradePerformance()
        }
    }
    
    /// 取消注册视图
    public func unregister(_ view: LiquidGlassView) {
        lock.lock()
        registeredViews.remove(view)
        let count = registeredViews.count
        lock.unlock()
        
        // 自适应升级
        if adaptivePerformance && count <= maxConcurrentViews / 2 {
            upgradePerformance()
        }
    }
    
    // MARK: - Control
    
    /// 暂停所有渲染
    public func pauseAll() {
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        
        for view in views {
            view.isPaused = true
        }
    }
    
    /// 恢复所有渲染
    public func resumeAll() {
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        
        for view in views {
            view.isPaused = false
        }
    }
    
    /// 强制重新捕获所有背景
    public func invalidateAllBackgrounds() {
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        
        for view in views {
            view.captureBackground()
        }
    }
    
    /// 释放所有缓存
    public func releaseAllCaches() {
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        
        for view in views {
            view.releaseCache()
        }
        
        LiquidGlassTexturePool.shared.purge()
    }
    
    // MARK: - Statistics
    
    /// 当前活跃视图数量
    public var activeViewCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return registeredViews.count
    }
    
    /// 性能统计
    public func getStatistics() -> Statistics {
        lock.lock()
        let count = registeredViews.count
        lock.unlock()
        
        return Statistics(
            activeViews: count,
            frameRate: globalFrameRate,
            performanceMode: performanceMode,
            texturePoolStats: LiquidGlassTexturePool.shared.debugDescription
        )
    }
    
    public struct Statistics {
        public let activeViews: Int
        public let frameRate: Int
        public let performanceMode: LiquidGlassPerformanceMode
        public let texturePoolStats: String
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        let nc = NotificationCenter.default
        
        nc.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        if autoDowngradeOnMemoryWarning {
            downgradePerformance()
            releaseAllCaches()
        }
    }
    
    @objc private func handleAppDidEnterBackground() {
        pauseAll()
    }
    
    @objc private func handleAppWillEnterForeground() {
        invalidateAllBackgrounds()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.resumeAll()
        }
    }
    
    private func downgradePerformance() {
        switch performanceMode {
        case .quality:
            performanceMode = .balanced
        case .balanced:
            performanceMode = .efficiency
        case .efficiency, .static:
            break
        }
    }
    
    private func upgradePerformance() {
        switch performanceMode {
        case .efficiency:
            performanceMode = .balanced
        case .static:
            performanceMode = .efficiency
        case .quality, .balanced:
            break
        }
    }
    
    private func applyPerformanceMode() {
        globalFrameRate = performanceMode.frameRate
        
        lock.lock()
        let views = registeredViews.allObjects
        lock.unlock()
        
        for view in views {
            applySettingsToView(view)
        }
    }
    
    private func applySettingsToView(_ view: LiquidGlassView) {
        view.targetFrameRate = globalFrameRate
        view.backgroundCaptureFrameRate = performanceMode.backgroundCaptureRate
    }
}
