//
//  BackdropCapture.swift
//  LiquidGlassEffect
//
//  背景捕获管理器 - 从 LiquidGlassView 中提取的背景捕获逻辑
//

import UIKit
import Metal
import MetalPerformanceShaders

/// 背景捕获管理器
///
/// 负责捕获视图背后的内容并转换为 Metal 纹理。
/// 使用双缓冲机制避免渲染时出现黑框。
final class BackdropCapture {
    
    // MARK: - Properties
    
    /// 背景捕获帧率限制
    var captureFrameRate: Double = 30.0
    
    /// 上次捕获时间
    private var lastCaptureTime: CFTimeInterval = 0
    
    /// 上次全局位置
    private var lastGlobalPosition: CGPoint = .zero
    
    /// 双缓冲纹理 A
    private var textureA: MTLTexture? {
        didSet {
            if let old = oldValue, old !== textureA {
                LiquidGlassTexturePool.shared.checkin(old)
            }
        }
    }
    
    /// 双缓冲纹理 B
    private var textureB: MTLTexture? {
        didSet {
            if let old = oldValue, old !== textureB {
                LiquidGlassTexturePool.shared.checkin(old)
            }
        }
    }
    
    /// 当前使用纹理 A
    private var useTextureA: Bool = true
    
    /// 静态快照纹理
    private var staticSnapshotTexture: MTLTexture? {
        didSet {
            if let old = oldValue, old !== staticSnapshotTexture {
                LiquidGlassTexturePool.shared.checkin(old)
            }
        }
    }
    
    /// 是否冻结（静态模式）
    private(set) var isFrozen: Bool = false
    
    /// 背景视图
    private let backdropView = BackdropView()
    
    /// 零拷贝桥接
    private var zeroCopyBridge: ZeroCopyBridge?
    
    /// 命令队列（用于模糊和拷贝）
    private weak var commandQueue: MTLCommandQueue?
    
    /// 配置
    private let config: LiquidGlassConfig
    
    // MARK: - Init
    
    init(device: MTLDevice, commandQueue: MTLCommandQueue, config: LiquidGlassConfig) {
        self.commandQueue = commandQueue
        self.config = config
        self.zeroCopyBridge = ZeroCopyBridge(device: device)
    }
    
    deinit {
        releaseAll()
    }
    
    // MARK: - Public API
    
    /// 获取当前可用的纹理
    var currentTexture: MTLTexture? {
        if isFrozen {
            return staticSnapshotTexture
        }
        // 优先使用最新的纹理
        return useTextureA ? (textureB ?? textureA) : (textureA ?? textureB)
    }
    
    /// 设置缓冲区尺寸
    func setupBuffer(width: Int, height: Int) {
        zeroCopyBridge?.setupBuffer(width: width, height: height)
    }
    
    /// 捕获背景
    /// - Parameters:
    ///   - view: 液态玻璃视图
    ///   - contentsScale: 内容缩放系数
    /// - Returns: 是否位置发生变化
    @discardableResult
    func capture(for view: UIView, contentsScale: CGFloat) -> Bool {
        guard let superview = view.superview,
              let zeroCopyBridge = zeroCopyBridge else { return false }
        
        let currentTime = CACurrentMediaTime()
        let interval = 1.0 / captureFrameRate
        
        // 计算全局位置
        let currentGlobalPosition = view.convert(view.bounds.origin, to: nil)
        let positionChanged = abs(currentGlobalPosition.x - lastGlobalPosition.x) > 0.5 ||
                              abs(currentGlobalPosition.y - lastGlobalPosition.y) > 0.5
        
        // 检查是否需要捕获
        guard positionChanged || currentTime - lastCaptureTime >= interval else {
            // 检查是否进入静态模式
            if currentTime - lastCaptureTime > 2.0 && !positionChanged {
                enterFrozenState()
            }
            return false
        }
        
        // 退出冻结状态
        if isFrozen {
            exitFrozenState()
        }
        
        // 执行捕获
        performCapture(view: view, superview: superview, zeroCopyBridge: zeroCopyBridge, contentsScale: contentsScale)
        
        lastCaptureTime = currentTime
        lastGlobalPosition = currentGlobalPosition
        
        return positionChanged
    }
    
    /// 强制重新捕获
    func invalidate() {
        textureA = nil
        textureB = nil
        lastCaptureTime = 0
    }
    
    /// 释放所有资源
    func releaseAll() {
        textureA = nil
        textureB = nil
        staticSnapshotTexture = nil
    }
    
    // MARK: - Private Methods
    
    private func performCapture(view: UIView, superview: UIView, zeroCopyBridge: ZeroCopyBridge, contentsScale: CGFloat) {
        let sizeCoeff = config.textureSizeCoefficient
        let scaleCoeff = contentsScale * config.textureScaleCoefficient
        
        // 使用 presentation layer 获取实时位置
        let currentLayer = view.layer.presentation() ?? view.layer
        let frameInSuperview = currentLayer.convert(currentLayer.bounds, to: superview.layer)
        
        // 计算捕获区域
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
            superview.insertSubview(backdropView, belowSubview: view)
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
                applyBlurAsync(to: texture, contentsScale: contentsScale)
            }
        }
    }
    
    private func applyBlurAsync(to texture: MTLTexture, contentsScale: CGFloat) {
        guard let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        var tex = texture
        let sigma = Float(config.blurRadius * Double(contentsScale))
        let blur = MPSImageGaussianBlur(device: commandQueue.device, sigma: sigma)
        blur.edgeMode = .clamp
        blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &tex, fallbackCopyAllocator: nil)
        commandBuffer.commit()
    }
    
    // MARK: - Frozen State
    
    private func enterFrozenState() {
        guard !isFrozen, let current = currentTexture, let commandQueue = commandQueue else { return }
        
        // 创建静态快照
        let descriptor = MTLTextureDescriptor()
        descriptor.width = current.width
        descriptor.height = current.height
        descriptor.pixelFormat = current.pixelFormat
        descriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let snapshot = LiquidGlassTexturePool.shared.checkout(descriptor: descriptor),
              let cmdBuffer = commandQueue.makeCommandBuffer(),
              let blitEncoder = cmdBuffer.makeBlitCommandEncoder() else { return }
        
        blitEncoder.copy(from: current, to: snapshot)
        blitEncoder.endEncoding()
        cmdBuffer.commit()
        
        staticSnapshotTexture = snapshot
        isFrozen = true
    }
    
    private func exitFrozenState() {
        isFrozen = false
        staticSnapshotTexture = nil
    }
}
