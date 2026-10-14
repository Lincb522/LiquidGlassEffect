//
//  LiquidGlassButton.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃按钮
//

import SwiftUI

// MARK: - Liquid Glass Button

/// 液态玻璃按钮
///
/// 带有液态玻璃背景和按压动画的通用按钮组件。
///
/// ```swift
/// LiquidGlassButton(action: { print("Tapped") }) {
///     Text("Click Me")
/// }
/// ```
public struct LiquidGlassButton<Label: View>: View {
    
    // MARK: - Properties
    
    private let action: () -> Void
    private let label: Label
    private let cornerRadius: CGFloat
    private let config: LiquidGlassConfig
    private let pressStyle: LiquidGlassPressableStyle
    
    // MARK: - Init
    
    public init(
        cornerRadius: CGFloat = 16,
        config: LiquidGlassConfig = .regular,
        pressStyle: LiquidGlassPressableStyle = .default,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.cornerRadius = cornerRadius
        self.config = config
        self.pressStyle = pressStyle
        self.action = action
        self.label = label()
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            label
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .liquidGlass(config: config, cornerRadius: cornerRadius)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(LiquidGlassNativeButtonStyle(pressStyle: pressStyle))
    }
}

// MARK: - Text Button

/// 液态玻璃文本按钮
///
/// 简化的文本按钮，预设样式。
public struct LiquidGlassTextButton: View {
    
    private let title: String
    private let action: () -> Void
    private let cornerRadius: CGFloat
    private let config: LiquidGlassConfig
    
    public init(
        _ title: String,
        cornerRadius: CGFloat = 16,
        config: LiquidGlassConfig = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.cornerRadius = cornerRadius
        self.config = config
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .liquidGlass(config: config, cornerRadius: cornerRadius)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(LiquidGlassNativeButtonStyle(pressStyle: .default))
    }
}

// MARK: - Icon Button

/// 液态玻璃图标按钮
///
/// 圆形图标按钮，支持激活状态。
///
/// ```swift
/// LiquidGlassIconButton(icon: "heart.fill", isActive: true) {
///     print("Liked")
/// }
/// ```
public struct LiquidGlassIconButton: View {
    
    // MARK: - Properties
    
    private let icon: String
    private let action: () -> Void
    private let size: CGFloat
    private let iconColor: Color
    private let isActive: Bool
    private let pressStyle: LiquidGlassPressableStyle
    
    // MARK: - Init
    
    public init(
        icon: String,
        size: CGFloat = 56,
        iconColor: Color = .white,
        isActive: Bool = false,
        pressStyle: LiquidGlassPressableStyle = .default,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconColor = iconColor
        self.isActive = isActive
        self.pressStyle = pressStyle
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                if isActive {
                    Circle().fill(.white)
                }

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(isActive ? .black : iconColor)
            }
            .frame(width: size, height: size)
            .liquidGlass(cornerRadius: size / 2)
            .contentShape(Circle())
        }
        .buttonStyle(LiquidGlassNativeButtonStyle(pressStyle: pressStyle))
    }
}

/// Preserve the existing scale/spring treatment while using native Button
/// activation, accessibility and disabled semantics. The finger-down state
/// drives the animation; pressDuration does not delay a native button action.
private struct LiquidGlassNativeButtonStyle: ButtonStyle {
    let pressStyle: LiquidGlassPressableStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressStyle.pressedScale : 1.0)
            .animation(
                .spring(response: pressStyle.responseTime, dampingFraction: pressStyle.dampingFraction),
                value: configuration.isPressed
            )
    }
}
