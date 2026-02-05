//
//  LiquidGlassSlider.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃垂直滑块
//

import SwiftUI

/// 液态玻璃垂直滑块
public struct LiquidGlassSlider: View {
    
    @Binding var value: Double
    var icon: String
    var iconColor: Color
    var height: CGFloat
    var cornerRadius: CGFloat
    var backgroundCaptureFrameRate: Double
    
    public init(
        value: Binding<Double>,
        icon: String = "circle.fill",
        iconColor: Color = .white,
        height: CGFloat = 160,
        cornerRadius: CGFloat = 20,
        backgroundCaptureFrameRate: Double = 30.0
    ) {
        self._value = value
        self.icon = icon
        self.iconColor = iconColor
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundCaptureFrameRate = backgroundCaptureFrameRate
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(iconColor.opacity(0.3))
                    .frame(height: geo.size.height * value)
                
                VStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(iconColor)
                        .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .liquidGlass(cornerRadius: cornerRadius, backgroundCaptureFrameRate: backgroundCaptureFrameRate)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = 1 - (gesture.location.y / geo.size.height)
                        value = max(0, min(1, newValue))
                    }
            )
        }
        .frame(height: height)
    }
}
