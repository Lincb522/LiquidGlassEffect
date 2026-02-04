//
//  LiquidGlassCard.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃卡片
//

import SwiftUI

/// 液态玻璃卡片
public struct LiquidGlassCard<Content: View>: View {
    
    let content: Content
    var cornerRadius: CGFloat
    var config: LiquidGlassConfig
    var padding: CGFloat
    
    public init(
        cornerRadius: CGFloat = 24,
        config: LiquidGlassConfig = .regular,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.config = config
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .liquidGlass(config: config, cornerRadius: cornerRadius)
    }
}
