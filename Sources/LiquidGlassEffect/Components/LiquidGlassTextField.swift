//
//  LiquidGlassTextField.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃输入框
//

import SwiftUI

/// 液态玻璃输入框
public struct LiquidGlassTextField: View {
    
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var cornerRadius: CGFloat
    var backgroundCaptureFrameRate: Double
    
    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        cornerRadius: CGFloat = 16,
        backgroundCaptureFrameRate: Double = 30.0
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.cornerRadius = cornerRadius
        self.backgroundCaptureFrameRate = backgroundCaptureFrameRate
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: cornerRadius, backgroundCaptureFrameRate: backgroundCaptureFrameRate)
    }
}
