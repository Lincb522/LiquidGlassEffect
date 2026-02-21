//
//  LiquidGlassGroup.swift
//  LiquidGlassEffect
//
//  共享背景上下文 - 允许子组件共享同一个背景纹理，大幅降低 CPU 捕获开销
//

import SwiftUI
import MetalKit

/// 共享捕获协调器
public class LiquidGlassGroupCoordinator: ObservableObject {
    
    @Published var sharedTexture: MTLTexture?
    @Published var captureRect: CGRect = .zero
    
    // 注册的子视图 (用于计算总包围盒)
    private var childFrames: [UUID: CGRect] = [:]
    
    // 捕获回调
    var onCaptureNeeded: (() -> Void)?
    
    public init() {}
    
    func updateChildFrame(id: UUID, frame: CGRect) {
        childFrames[id] = frame
        // 简单策略：每次子视图更新都重新计算总包围盒（实际应节流）
        let unionRect = childFrames.values.reduce(CGRect.null) { $0.union($1) }
        if !unionRect.isNull && unionRect != captureRect {
            captureRect = unionRect
            onCaptureNeeded?()
        }
    }
    
    func updateTexture(_ texture: MTLTexture) {
        self.sharedTexture = texture
    }
}

/// 液态玻璃分组容器
public struct LiquidGlassGroup<Content: View>: View {
    
    let content: Content
    @StateObject private var coordinator = LiquidGlassGroupCoordinator()
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .environment(\.liquidGlassGroupCoordinator, coordinator)
            .background(
                LiquidGlassGroupBackdrop(coordinator: coordinator)
            )
    }
}

/// 负责捕获大背景的视图
private struct LiquidGlassGroupBackdrop: UIViewRepresentable {
    
    @ObservedObject var coordinator: LiquidGlassGroupCoordinator
    
    func makeUIView(context: Context) -> LiquidGlassGroupBackdropView {
        let view = LiquidGlassGroupBackdropView()
        view.coordinator = coordinator
        return view
    }
    
    func updateUIView(_ uiView: LiquidGlassGroupBackdropView, context: Context) {
        // 更新逻辑
    }
}

class LiquidGlassGroupBackdropView: UIView {
    
    weak var coordinator: LiquidGlassGroupCoordinator?
    private var backdropView = BackdropView()
    private var zeroCopyBridge: ZeroCopyBridge?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.isHidden = true // 不直接显示，仅用于捕获
        
        if let device = LiquidGlassRenderer.shared?.device {
            zeroCopyBridge = ZeroCopyBridge(device: device)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func capture() {
        guard let superview = superview, let bridge = zeroCopyBridge, let coordinator = coordinator else { return }
        
        // 确保有合法的 captureRect
        // 这里我们直接使用 superview 的 bounds 作为简单的实现，
        // 实际上应该使用 coordinator.captureRect (子视图的联合包围盒)
        // 为了简化 Phase 2 的实现，我们先捕获整个 Group 的区域
        let captureFrame = self.frame
        
        // 准备 backdropView
        if backdropView.superview !== superview {
            superview.insertSubview(backdropView, at: 0) // 放在最底层
        }
        backdropView.frame = captureFrame
        backdropView.isHidden = true // 它是隐藏的，只用于 drawHierarchy
        
        // 使用 ZeroCopyBridge 捕获
        // let scale = UIScreen.main.scale // Removed unused variable
        let newTexture = bridge.render { context in
            // 需要反转 Y 轴吗？通常 UIKit 到 Metal 不需要，除非坐标系不同
            // 这里保持标准绘制
            UIGraphicsPushContext(context)
            // drawHierarchy 在屏幕外绘制可能需要特殊处理
            // 这里我们尝试绘制 superview 的层级，排除 self
            superview.drawHierarchy(in: superview.bounds, afterScreenUpdates: false)
            UIGraphicsPopContext()
        }
        
        if let texture = newTexture {
            // 更新 Coordinator
            DispatchQueue.main.async {
                coordinator.updateTexture(texture)
            }
        }
    }
    
    // 定时器触发捕获
    private var displayLink: CADisplayLink?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startCaptureLoop()
        } else {
            stopCaptureLoop()
        }
    }
    
    private func startCaptureLoop() {
        stopCaptureLoop()
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.preferredFramesPerSecond = 30 // 默认 30fps
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopCaptureLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleDisplayLink() {
        capture()
    }
}
