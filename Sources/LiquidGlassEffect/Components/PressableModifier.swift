//
//  PressableModifier.swift
//  LiquidGlassEffect
//
//  可按压效果修饰器 - 提取公共的按压动画逻辑
//

import SwiftUI

// MARK: - Pressable Style

/// 按压效果样式
public struct LiquidGlassPressableStyle {
    /// 按压时的缩放比例
    public let pressedScale: CGFloat
    /// 动画响应时间
    public let responseTime: Double
    /// 动画阻尼系数
    public let dampingFraction: Double
    /// 按压持续时间
    public let pressDuration: TimeInterval
    
    public init(
        pressedScale: CGFloat = 0.96,
        responseTime: Double = 0.3,
        dampingFraction: Double = 0.6,
        pressDuration: TimeInterval = 0.1
    ) {
        self.pressedScale = pressedScale
        self.responseTime = responseTime
        self.dampingFraction = dampingFraction
        self.pressDuration = pressDuration
    }
    
    /// 默认样式
    public static let `default` = LiquidGlassPressableStyle()
    
    /// 轻微按压
    public static let subtle = LiquidGlassPressableStyle(pressedScale: 0.98)
    
    /// 强烈按压
    public static let strong = LiquidGlassPressableStyle(pressedScale: 0.9)
    
    /// 快速响应
    public static let quick = LiquidGlassPressableStyle(
        pressedScale: 0.95,
        responseTime: 0.2,
        dampingFraction: 0.65,
        pressDuration: 0.08
    )
}

// MARK: - Pressable Modifier

/// 可按压效果修饰器
struct PressableModifier: ViewModifier {
    
    let style: LiquidGlassPressableStyle
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? style.pressedScale : 1.0)
            .animation(
                .spring(response: style.responseTime, dampingFraction: style.dampingFraction),
                value: isPressed
            )
            .onTapGesture {
                triggerPress()
            }
    }
    
    private func triggerPress() {
        // 触觉反馈
        if let hapticStyle = hapticStyle {
            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
            generator.impactOccurred()
        }
        
        // 按压动画
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + style.pressDuration) {
            isPressed = false
            action()
        }
    }
}

// MARK: - View Extension

public extension View {
    
    /// 添加可按压效果
    ///
    /// - Parameters:
    ///   - style: 按压样式
    ///   - haptic: 触觉反馈样式，nil 表示无反馈
    ///   - action: 点击回调
    func pressable(
        style: LiquidGlassPressableStyle = .default,
        haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .light,
        action: @escaping () -> Void
    ) -> some View {
        modifier(PressableModifier(style: style, action: action, hapticStyle: haptic))
    }
}
