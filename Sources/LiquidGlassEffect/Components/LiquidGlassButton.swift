//
//  LiquidGlassButton.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃按钮
//

import SwiftUI

/// 液态玻璃按钮
public struct LiquidGlassButton<Label: View>: View {
    
    let action: () -> Void
    let label: Label
    var cornerRadius: CGFloat
    var config: LiquidGlassConfig
    
    @State private var isPressed = false
    
    public init(
        cornerRadius: CGFloat = 16,
        config: LiquidGlassConfig = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.cornerRadius = cornerRadius
        self.config = config
        self.action = action
        self.label = label()
    }
    
    public var body: some View {
        label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .liquidGlass(config: config, cornerRadius: cornerRadius)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    action()
                }
            }
    }
}

/// 液态玻璃图标按钮
public struct LiquidGlassIconButton: View {
    
    let icon: String
    let action: () -> Void
    var size: CGFloat
    var iconColor: Color
    var isActive: Bool
    
    @State private var isPressed = false
    
    public init(
        icon: String,
        size: CGFloat = 56,
        iconColor: Color = .white,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.iconColor = iconColor
        self.isActive = isActive
        self.action = action
    }
    
    public var body: some View {
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
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }
    }
}
