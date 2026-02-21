//
//  LiquidGlassCard.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃卡片
//

import SwiftUI

// MARK: - Liquid Glass Card

/// 液态玻璃卡片
///
/// 带有液态玻璃背景的内容容器。
///
/// ```swift
/// LiquidGlassCard {
///     VStack {
///         Text("Title")
///         Text("Content")
///     }
/// }
/// ```
public struct LiquidGlassCard<Content: View>: View {
    
    // MARK: - Properties
    
    private let content: Content
    private let cornerRadius: CGFloat
    private let config: LiquidGlassConfig
    private let padding: CGFloat
    private let backgroundCaptureFrameRate: Double
    
    // MARK: - Init
    
    public init(
        cornerRadius: CGFloat = 24,
        config: LiquidGlassConfig = .regular,
        padding: CGFloat = 16,
        backgroundCaptureFrameRate: Double = 30.0,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.config = config
        self.padding = padding
        self.backgroundCaptureFrameRate = backgroundCaptureFrameRate
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .padding(padding)
            .liquidGlass(
                config: config,
                cornerRadius: cornerRadius,
                backgroundCaptureFrameRate: backgroundCaptureFrameRate
            )
    }
}

// MARK: - Liquid Glass Container

/// 液态玻璃容器
///
/// 用于包裹内容的基础容器，不添加额外 padding。
/// 主要用于 TabBar 等需要精确控制布局的场景。
public struct LiquidGlassContainer<Content: View>: View {
    
    // MARK: - Properties
    
    private let config: LiquidGlassConfig
    private let cornerRadius: CGFloat
    private let content: Content
    
    // MARK: - Init
    
    public init(
        config: LiquidGlassConfig = .regular,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.config = config
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .background {
                LiquidGlassMetalView(config: config, cornerRadius: cornerRadius)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
