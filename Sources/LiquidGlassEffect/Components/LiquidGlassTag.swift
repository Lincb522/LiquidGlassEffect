//
//  LiquidGlassTag.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃标签
//

import SwiftUI

// MARK: - Tag

/// 液态玻璃标签
///
/// 适用于标签、徽章等小型组件。
///
/// ```swift
/// LiquidGlassTag("New", icon: "sparkles")
/// ```
public struct LiquidGlassTag: View {
    
    // MARK: - Properties
    
    private let text: String
    private let icon: String?
    private let config: LiquidGlassConfig
    
    // MARK: - Init
    
    public init(
        _ text: String,
        icon: String? = nil,
        config: LiquidGlassConfig = .subtle
    ) {
        self.text = text
        self.icon = icon
        self.config = config
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .liquidGlass(config: config, cornerRadius: 12)
    }
}

// MARK: - Badge

/// 液态玻璃徽章
///
/// 用于显示数字或状态的小型圆形徽章。
public struct LiquidGlassBadge: View {
    
    // MARK: - Properties
    
    private let count: Int
    private let maxCount: Int
    private let color: Color
    
    // MARK: - Init
    
    public init(
        count: Int,
        maxCount: Int = 99,
        color: Color = .red
    ) {
        self.count = count
        self.maxCount = maxCount
        self.color = color
    }
    
    // MARK: - Body
    
    public var body: some View {
        if count > 0 {
            Text(count > maxCount ? "\(maxCount)+" : "\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, count > 9 ? 6 : 0)
                .frame(minWidth: 18, minHeight: 18)
                .background(color)
                .clipShape(Capsule())
        }
    }
}
