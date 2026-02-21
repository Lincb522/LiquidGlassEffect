//
//  LiquidGlassToggle.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃开关
//

import SwiftUI

// MARK: - Toggle

/// 液态玻璃开关
///
/// 带有液态玻璃背景的开关组件。
///
/// ```swift
/// @State var isEnabled = false
/// LiquidGlassToggle(isOn: $isEnabled, onColor: .green)
/// ```
public struct LiquidGlassToggle: View {
    
    // MARK: - Properties
    
    @Binding var isOn: Bool
    
    private let onColor: Color
    private let backgroundCaptureFrameRate: Double
    
    // MARK: - Init
    
    public init(
        isOn: Binding<Bool>,
        onColor: Color = .green,
        backgroundCaptureFrameRate: Double = 30.0
    ) {
        self._isOn = isOn
        self.onColor = onColor
        self.backgroundCaptureFrameRate = backgroundCaptureFrameRate
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // 背景
            Capsule()
                .fill(isOn ? onColor.opacity(0.5) : Color.white.opacity(0.1))
                .frame(width: 52, height: 32)
            
            // 滑块
            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .offset(x: isOn ? 10 : -10)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        }
        .liquidGlass(
            cornerRadius: 16,
            backgroundCaptureFrameRate: backgroundCaptureFrameRate
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Labeled Toggle

/// 带标签的液态玻璃开关
public struct LiquidGlassLabeledToggle: View {
    
    // MARK: - Properties
    
    private let title: String
    private let subtitle: String?
    @Binding var isOn: Bool
    
    private let onColor: Color
    
    // MARK: - Init
    
    public init(
        _ title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        onColor: Color = .green
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onColor = onColor
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            LiquidGlassToggle(isOn: $isOn, onColor: onColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 16)
    }
}
