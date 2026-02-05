//
//  LiquidGlassNotification.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃通知卡片
//

import SwiftUI

// MARK: - Notification

/// 液态玻璃通知卡片
///
/// 适用于推送通知、消息提示等场景。
///
/// ```swift
/// LiquidGlassNotification(
///     icon: "bell.fill",
///     title: "New Message",
///     message: "You have a new message"
/// )
/// ```
public struct LiquidGlassNotification: View {
    
    // MARK: - Properties
    
    private let icon: String
    private let title: String
    private let message: String
    private let iconColor: Color
    private let config: LiquidGlassConfig
    private let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            // 文本
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

// MARK: - Toast

/// 液态玻璃 Toast 提示
///
/// 轻量级的提示组件，适用于操作反馈。
public struct LiquidGlassToast: View {
    
    // MARK: - Properties
    
    private let message: String
    private let icon: String?
    
    // MARK: - Init
    
    public init(
        _ message: String,
        icon: String? = nil
    ) {
        self.message = message
        self.icon = icon
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlass(config: .subtle, cornerRadius: 20)
    }
}
