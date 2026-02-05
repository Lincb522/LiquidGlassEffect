//
//  LiquidGlassView.swift
//  LiquidGlassEffect
//
//  液态玻璃效果 MTKView（高性能版）
//  Credits: https://github.com/DnV1eX/LiquidGlassKit
//

import UIKit
import MetalKit

/// 液态玻璃效果视图
///
/// 基于 Metal 的高性能液态玻璃效果实现。
/// 支持实时背景捕获、双缓冲渲染、静态快照优化。
public final class LiquidGlassView: MTKView {
    
    // MARK: - Public Properties
    
    /// 配置
    public let config: LiquidGlassConfig
    
    /// 帧率限制
    public var targetFrameRate: Int = 60 {
        didSet { preferredFramesPerSecond = targetFrameRate }
    }
    
    /// 背景捕获帧率限制
    public var backgroundCaptureFrameRate: Double = 30.0 {
        didSet { backdropCapture?.captureFrameRate = backgroundCaptureFrameRate }
    }
    
    /// 是否自动捕获背景
    public var autoCapture: Bool = true
    
    /// 触摸点（用于交互效果）
    public var touchPoint: CGPoint? = nil
    
    /// 玻璃矩形区域
    public var frames: [CGRect] = []
    
    /// 共享协调器（用于 LiquidGlassGroup）
    public weak var groupCoordinator: LiquidGlassGroupCoordinator?
    
    /// Metal 是否可用
    public private(set) var isMetalAvailable: Bool = false
    
    // MARK: - Private Properties
    
    private var commandQueue: MTLCommandQueue?
    private var uniformsBuffer: MTLBuffer?
    private var backdropCapture: BackdropCapture?
    private weak var shadowView: ShadowView?
    private var lastLayoutSize: CGSize = .zero
    private var isRegisteredToEngine: Bool = false
    
    // MARK: - Init
    
    public init(_ config: LiquidGlassConfig = .regular) {
        self.config = config
        super.init(frame: .zero, device: LiquidGlassRenderer.shared?.device)
        
        if config.shadowOverlay {
            let shadow = ShadowView()
            addSubview(shadow)
            self.shadowView = shadow
        }
        
        setupMetal()
        registerToEngine()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    deinit {
        unregisterFromEngine()
    }
    
    // MARK: - Setup
    
    private func setupMetal() {
        guard let device = device,
              let queue = device.makeCommandQueue(),
              let buffer = device.makeBuffer(length: MemoryLayout<LiquidGlassUniforms>.stride, options: .storageModeShared)
        else {
            print("[LiquidGlassEffect] Metal device not available")
            isMetalAvailable = false
            return
        }
        
        commandQueue = queue
        uniformsBuffer = buffer
        backdropCapture = BackdropCapture(device: device, commandQueue: queue, config: config)
        backdropCapture?.captureFrameRate = backgroundCaptureFrameRate
        
        configureView()
        isMetalAvailable = true
    }
    
    private func configureView() {
        isOpaque = false
        layer.isOpaque = false
        backgroundColor = .clear
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        isPaused = false
        preferredFramesPerSecond = 60
        enableSetNeedsDisplay = false
        presentsWithTransaction = false
        framebufferOnly = false
    }
    
    // MARK: - Engine Integration
    
    private func registerToEngine() {
        guard !isRegisteredToEngine else { return }
        LiquidGlassEngine.shared.register(self)
        isRegisteredToEngine = true
    }
    
    private func unregisterFromEngine() {
        guard isRegisteredToEngine else { return }
        LiquidGlassEngine.shared.unregister(self)
        isRegisteredToEngine = false
    }
    
    // MARK: - Public API
    
    /// 强制重新捕获背景
    public func captureBackground() {
        backdropCapture?.invalidate()
    }
    
    /// 释放缓存
    public func releaseCache() {
        backdropCapture?.releaseAll()
    }
    
    /// 设置捕获间隔（兼容旧 API）
    public func setCaptureInterval(_ interval: Int) {
        // 兼容旧 API
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard isMetalAvailable else { return }
        
        let currentSize = bounds.size
        guard currentSize != lastLayoutSize, currentSize.width > 0, currentSize.height > 0 else { return }
        lastLayoutSize = currentSize
        
        updateUniforms()
        
        // 更新背景捕获缓冲区
        let scale = layer.contentsScale * CGFloat(config.textureSizeCoefficient * config.textureScaleCoefficient)
        backdropCapture?.setupBuffer(
            width: Int(bounds.width * scale),
            height: Int(bounds.height * scale)
        )
        
        shadowView?.frame = bounds
    }
    
    // MARK: - Draw
    
    public override func draw(_ rect: CGRect) {
        guard isMetalAvailable, let renderer = LiquidGlassRenderer.shared else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // 捕获背景
        if autoCapture && groupCoordinator == nil {
            backdropCapture?.capture(for: self, contentsScale: layer.contentsScale)
        }
        
        // 获取纹理
        var textureToUse = backdropCapture?.currentTexture
        if let shared = groupCoordinator?.sharedTexture {
            textureToUse = shared
        }
        
        // 渲染
        guard let drawable = currentDrawable,
              let renderPassDesc = currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
        
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDesc.colorAttachments[0].loadAction = .clear
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }
        
        if let texture = textureToUse {
            encoder.setRenderPipelineState(renderer.pipelineState)
            encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Uniforms
    
    private func updateUniforms() {
        guard let uniformsBuffer = uniformsBuffer else { return }
        
        var uniforms = config.uniforms
        let scale = layer.contentsScale
        
        uniforms.resolution = .init(x: Float(bounds.width * scale), y: Float(bounds.height * scale))
        uniforms.contentsScale = Float(scale)
        uniforms.shapeMergeSmoothness = 0.2
        uniforms.cornerRadius = Float(layer.cornerRadius)
        
        // UV 映射
        updateUVMapping(&uniforms)
        
        // 触摸点
        if let touchPoint = touchPoint {
            uniforms.touchPoint = .init(x: Float(touchPoint.x), y: Float(touchPoint.y))
        }
        
        // 矩形区域
        let effectiveFrames = frames.isEmpty ? [bounds] : frames
        uniforms.rectangleCount = Int32(min(effectiveFrames.count, LiquidGlassConfig.maxRectangles))
        
        // 写入 buffer
        let ptr = uniformsBuffer.contents().assumingMemoryBound(to: LiquidGlassUniforms.self)
        ptr.pointee = uniforms
        
        // 写入矩形数据
        withUnsafeMutablePointer(to: &ptr.pointee.rectangles) { rectPtr in
            let base = UnsafeMutableRawPointer(rectPtr).assumingMemoryBound(to: SIMD4<Float>.self)
            for i in 0..<LiquidGlassConfig.maxRectangles {
                if i < effectiveFrames.count {
                    let frame = effectiveFrames[i]
                    base[i] = SIMD4<Float>(Float(frame.origin.x), Float(frame.origin.y), Float(frame.width), Float(frame.height))
                } else {
                    base[i] = .zero
                }
            }
        }
    }
    
    private func updateUVMapping(_ uniforms: inout LiquidGlassUniforms) {
        guard let coordinator = groupCoordinator, let window = window else {
            uniforms.uvScale = SIMD2<Float>(1.0, 1.0)
            uniforms.uvOffset = SIMD2<Float>(0.0, 0.0)
            return
        }
        
        let captureRect = coordinator.captureRect
        let globalFrame = convert(bounds, to: window)
        
        let scaleX = Float(globalFrame.width / captureRect.width)
        let scaleY = Float(globalFrame.height / captureRect.height)
        let offsetX = Float((globalFrame.minX - captureRect.minX) / captureRect.width)
        let offsetY = Float((globalFrame.minY - captureRect.minY) / captureRect.height)
        
        uniforms.uvScale = SIMD2<Float>(scaleX, scaleY)
        uniforms.uvOffset = SIMD2<Float>(offsetX, offsetY)
    }
    
    // MARK: - Window
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            isPaused = true
        } else {
            isPaused = false
            backdropCapture?.invalidate()
        }
    }
    
    // MARK: - Hit Test
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
