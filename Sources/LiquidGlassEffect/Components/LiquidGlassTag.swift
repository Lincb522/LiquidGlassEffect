//
//  LiquidGlassTag.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃标签
//

import SwiftUI

/// 液态玻璃标签
public struct LiquidGlassTag: View {
    
    let text: String
    var icon: String?
    var config: LiquidGlassConfig
    
    public init(
        _ text: String,
        icon: String? = nil,
        config: LiquidGlassConfig = .subtle
    ) {
        self.text = text
        self.icon = icon
        self.config = config
    }
    
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
