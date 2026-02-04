//
//  LiquidGlassEngine.swift
//  LiquidGlassEffect
//
//  性能优化引擎 - 统一管理所有液态玻璃视图的渲染
//

import UIKit
import Metal
import QuartzCore

/// 性能模式
public enum LiquidGlassPerformanceMode {
    /// 高质量（60fps，流畅滑动）
    case quality
    /// 平衡（60fps，适度优化）
    case balanced
    /// 省电（30fps，降低功耗）
    case efficiency
    /// 静态（仅在需要时渲染）
    case `static`
    
    var frameRate: Int {
        switch self {
        case .quality: return 60
        case .balanced: return 60  // 保持 60fps 避免卡顿
        case .efficiency: return 30
        case .static: return 15
        }
    }
}

/// 液态玻璃性能优化引擎
public final class LiquidGlassEngine {
    
    // MARK: - Singleton
    
    public static let shared = LiquidGlassEngine()
    
    // MARK: - Properties
    
    /// 当前性能模式
    public var performanceMode: LiquidGlassPerformanceMode = .balanced {
        didSet { applyPerformanceMode() }
    }
    
    /// 全局帧率限制
    public var globalFrameRate: Int = 60 {
        didSet { notifyViewsFrameRateChanged() }
    }
    
    /// 是否启用自适应性能（根据设备负载自动调整）
    public var adaptivePerformance: Bool = true
    
    /// 最大同时渲染的视图数量
    public var maxConcurrentViews: Int = 10
    
    /// 内存警告时自动降级
    public var autoDowngradeOnMemoryWarning: Bool = true
    
    // MARK: - Internal State
    
    private var registeredViews: NSHashTable<LiquidGlassView> = .weakObjects()
    
    // MARK: - Init
    
    private init() {
        setupMemoryWarningObserver()
        setupAppStateObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Registration
    
    /// 注册视图到引擎管理
    public func register(_ view: LiquidGlassView) {
        registeredViews.add(view)
        applySettingsToView(view)
        
        // 检查是否超过最大数量
        if registeredViews.count > maxConcurrentViews && adaptivePerformance {
            downgradePerformance()
        }
    }
    
    /// 取消注册视图
    public func unregister(_ view: LiquidGlassView) {
        registeredViews.remove(view)
        
        // 视图减少时可以提升性能
        if adaptivePerformance && registeredViews.count <= maxConcurrentViews / 2 {
            upgradePerformance()
        }
    }
    
    // MARK: - Performance Control
    
    /// 暂停所有渲染（进入后台时调用）
    public func pauseAll() {
        for view in registeredViews.allObjects {
            view.isPaused = true
        }
    }
    
    /// 恢复所有渲染
    public func resumeAll() {
        for view in registeredViews.allObjects {
            view.isPaused = false
        }
    }
    
    /// 强制所有视图重新捕获背景
    public func invalidateAllBackgrounds() {
        for view in registeredViews.allObjects {
            view.captureBackground()
        }
    }
    
    /// 释放所有缓存（内存紧张时调用）
    public func releaseAllCaches() {
        for view in registeredViews.allObjects {
            view.releaseCache()
        }
    }
    
    // MARK: - Adaptive Performance
    
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
        notifyViewsFrameRateChanged()
    }
    
    private func applySettingsToView(_ view: LiquidGlassView) {
        view.targetFrameRate = globalFrameRate
    }
    
    private func notifyViewsFrameRateChanged() {
        for view in registeredViews.allObjects {
            view.targetFrameRate = globalFrameRate
        }
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        if autoDowngradeOnMemoryWarning {
            downgradePerformance()
            releaseAllCaches()
        }
    }
    
    // MARK: - App State
    
    private func setupAppStateObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidEnterBackground() {
        pauseAll()
    }
    
    @objc private func handleAppWillEnterForeground() {
        resumeAll()
        invalidateAllBackgrounds()
    }
    
    // MARK: - Statistics
    
    /// 当前注册的视图数量
    public var activeViewCount: Int {
        registeredViews.count
    }
    
    /// 获取性能统计信息
    public func getStatistics() -> PerformanceStatistics {
        PerformanceStatistics(
            activeViews: registeredViews.count,
            frameRate: globalFrameRate,
            performanceMode: performanceMode
        )
    }
    
    public struct PerformanceStatistics {
        public let activeViews: Int
        public let frameRate: Int
        public let performanceMode: LiquidGlassPerformanceMode
    }
}
