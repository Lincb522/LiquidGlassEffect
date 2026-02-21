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
    
    // MARK: - Properties
    
    public let config: LiquidGlassConfig
    public let cornerRadius: CGFloat
    public let backgroundCaptureFrameRate: Double
    
    @Environment(\.liquidGlassGroupCoordinator) private var groupCoordinator
    
    // MARK: - Init
    
    public init(
        config: LiquidGlassConfig = .regular,
        cornerRadius: CGFloat = 0,
        backgroundCaptureFrameRate: Double = 60.0
    ) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.backgroundCaptureFrameRate = backgroundCaptureFrameRate
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> LiquidGlassView {
        let view = LiquidGlassView(config)
        configureView(view)
        return view
    }
    
    public func updateUIView(_ uiView: LiquidGlassView, context: Context) {
        uiView.layer.cornerRadius = cornerRadius
        uiView.backgroundCaptureFrameRate = backgroundCaptureFrameRate
        
        if uiView.groupCoordinator !== groupCoordinator {
            uiView.groupCoordinator = groupCoordinator
        }
    }
    
    public static func dismantleUIView(_ uiView: LiquidGlassView, coordinator: ()) {
        // 视图销毁时自动从引擎注销（在 deinit 中处理）
    }
    
    // MARK: - Private
    
    private func configureView(_ view: LiquidGlassView) {
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.backgroundCaptureFrameRate = backgroundCaptureFrameRate
        view.isUserInteractionEnabled = true
        view.groupCoordinator = groupCoordinator
    }
}

// MARK: - View Extension

public extension View {
    
    /// 应用液态玻璃效果
    ///
    /// - Parameters:
    ///   - config: 效果配置，默认 `.regular`
    ///   - cornerRadius: 圆角半径，默认 20
    ///   - backgroundCaptureFrameRate: 背景捕获帧率，默认 30
    /// - Returns: 应用了液态玻璃效果的视图
    func liquidGlass(
        config: LiquidGlassConfig = .regular,
        cornerRadius: CGFloat = 20,
        backgroundCaptureFrameRate: Double = 60.0
    ) -> some View {
        background(
            LiquidGlassMetalView(
                config: config,
                cornerRadius: cornerRadius,
                backgroundCaptureFrameRate: backgroundCaptureFrameRate
            )
        )
    }
    
    /// 应用镜头效果
    ///
    /// 适用于需要聚焦效果的场景，如 TabBar 指示器。
    func liquidGlassLens(
        cornerRadius: CGFloat = 20,
        backgroundCaptureFrameRate: Double = 60.0
    ) -> some View {
        liquidGlass(
            config: .lens,
            cornerRadius: cornerRadius,
            backgroundCaptureFrameRate: backgroundCaptureFrameRate
        )
    }
    
    /// 应用轻微效果
    ///
    /// 最小折射，适用于不需要强烈视觉效果的场景。
    func liquidGlassSubtle(
        cornerRadius: CGFloat = 16,
        backgroundCaptureFrameRate: Double = 60.0
    ) -> some View {
        liquidGlass(
            config: .subtle,
            cornerRadius: cornerRadius,
            backgroundCaptureFrameRate: backgroundCaptureFrameRate
        )
    }
    
    /// 应用缩略图效果
    ///
    /// 适用于小尺寸组件，如 TabBar 气泡、小按钮。
    func liquidGlassThumb(
        magnification: Double = 1,
        cornerRadius: CGFloat = 12,
        backgroundCaptureFrameRate: Double = 60.0
    ) -> some View {
        liquidGlass(
            config: .thumb(magnification: magnification),
            cornerRadius: cornerRadius,
            backgroundCaptureFrameRate: backgroundCaptureFrameRate
        )
    }
}

// MARK: - Performance Control

public extension View {
    
    /// 设置液态玻璃性能模式
    ///
    /// 在视图出现时应用指定的性能模式。
    func liquidGlassPerformance(_ mode: LiquidGlassPerformanceMode) -> some View {
        onAppear {
            LiquidGlassEngine.shared.performanceMode = mode
        }
    }
}

// MARK: - Deprecated

public extension View {
    
    @available(*, deprecated, renamed: "liquidGlass")
    func liquidGlassMetal(
        config: LiquidGlassConfig = .regular,
        cornerRadius: CGFloat = 20
    ) -> some View {
        liquidGlass(config: config, cornerRadius: cornerRadius)
    }
}
