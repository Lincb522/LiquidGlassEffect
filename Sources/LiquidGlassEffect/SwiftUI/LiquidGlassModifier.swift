//
//  LiquidGlassModifier.swift
//  LiquidGlassEffect
//
//  SwiftUI View Modifier
//

import SwiftUI

// MARK: - UIViewRepresentable

/// SwiftUI 包装的液态玻璃视图
public struct LiquidGlassMetalView: UIViewRepresentable {
    
    public var config: LiquidGlassConfig
    public var cornerRadius: CGFloat
    
    public init(config: LiquidGlassConfig = .regular, cornerRadius: CGFloat = 0) {
        self.config = config
        self.cornerRadius = cornerRadius
    }
    
    public func makeUIView(context: Context) -> LiquidGlassView {
        let view = LiquidGlassView(config)
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }
    
    public func updateUIView(_ uiView: LiquidGlassView, context: Context) {
        uiView.layer.cornerRadius = cornerRadius
    }
    
    public static func dismantleUIView(_ uiView: LiquidGlassView, coordinator: ()) {
        // 视图销毁时自动从引擎注销
    }
}

// MARK: - View Modifiers

public extension View {
    
    /// 应用液态玻璃效果
    func liquidGlass(config: LiquidGlassConfig = .regular, cornerRadius: CGFloat = 20) -> some View {
        self.background(LiquidGlassMetalView(config: config, cornerRadius: cornerRadius))
    }
    
    /// 应用镜头效果
    func liquidGlassLens(cornerRadius: CGFloat = 20) -> some View {
        self.background(LiquidGlassMetalView(config: .lens, cornerRadius: cornerRadius))
    }
    
    /// 应用轻微效果
    func liquidGlassSubtle(cornerRadius: CGFloat = 16) -> some View {
        self.background(LiquidGlassMetalView(config: .subtle, cornerRadius: cornerRadius))
    }
}

// MARK: - Performance Control

public extension View {
    
    /// 设置液态玻璃性能模式
    func liquidGlassPerformance(_ mode: LiquidGlassPerformanceMode) -> some View {
        self.onAppear {
            LiquidGlassEngine.shared.performanceMode = mode
        }
    }
}

// MARK: - Deprecated (兼容旧 API)

public extension View {
    
    @available(*, deprecated, renamed: "liquidGlass")
    func liquidGlassMetal(config: LiquidGlassConfig = .regular, cornerRadius: CGFloat = 20) -> some View {
        liquidGlass(config: config, cornerRadius: cornerRadius)
    }
}
