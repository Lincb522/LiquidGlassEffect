//
//  LiquidGlassTextField.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃输入框
//

import SwiftUI

// MARK: - Text Field

/// 液态玻璃输入框
///
/// 带有液态玻璃背景的文本输入框。
///
/// ```swift
/// @State var text = ""
/// LiquidGlassTextField("Search...", text: $text, icon: "magnifyingglass")
/// ```
public struct LiquidGlassTextField: View {
    
    // MARK: - Properties
    
    private let placeholder: String
    @Binding var text: String
    
    private let icon: String?
    private let cornerRadius: CGFloat
    private let backgroundCaptureFrameRate: Double
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
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
        .liquidGlass(
            cornerRadius: cornerRadius,
            backgroundCaptureFrameRate: backgroundCaptureFrameRate
        )
    }
}

// MARK: - Secure Field

/// 液态玻璃密码输入框
public struct LiquidGlassSecureField: View {
    
    // MARK: - Properties
    
    private let placeholder: String
    @Binding var text: String
    
    private let icon: String?
    private let cornerRadius: CGFloat
    
    @State private var isSecure = true
    
    // MARK: - Init
    
    public init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = "lock.fill",
        cornerRadius: CGFloat = 16
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
            }
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: cornerRadius)
    }
}
