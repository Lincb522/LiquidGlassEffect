//
//  LiquidGlassNotification.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃通知卡片
//

import SwiftUI

/// 液态玻璃通知卡片
public struct LiquidGlassNotification: View {
    
    let icon: String
    let title: String
    let message: String
    var iconColor: Color
    var config: LiquidGlassConfig
    var onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    public init(
        icon: String,
        title: String,
        message: String,
        iconColor: Color = .white,
        config: LiquidGlassConfig = .regular,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.config = config
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .liquidGlass(config: config, cornerRadius: 20)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            guard let onTap = onTap else { return }
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
    }
}
