//
//  LiquidGlassSlider.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃滑块
//

import SwiftUI

// MARK: - Vertical Slider

/// 液态玻璃垂直滑块
///
/// 适用于音量、亮度等控制场景。
///
/// ```swift
/// @State var volume: Double = 0.5
/// LiquidGlassSlider(value: $volume, icon: "speaker.wave.2.fill")
/// ```
public struct LiquidGlassSlider: View {
    
    // MARK: - Properties
    
    @Binding var value: Double
    
    private let icon: String
    private let iconColor: Color
    private let height: CGFloat
    private let cornerRadius: CGFloat
    private let backgroundCaptureFrameRate: Double
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // 填充层
                Rectangle()
                    .fill(iconColor.opacity(0.3))
                    .frame(height: geo.size.height * value)
                
                // 图标
                VStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(iconColor)
                        .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .liquidGlass(
                cornerRadius: cornerRadius,
                backgroundCaptureFrameRate: backgroundCaptureFrameRate
            )
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

// MARK: - Horizontal Slider

/// 液态玻璃水平滑块
///
/// 适用于进度条、播放进度等场景。
public struct LiquidGlassHorizontalSlider: View {
    
    // MARK: - Properties
    
    @Binding var value: Double
    
    private let tintColor: Color
    private let height: CGFloat
    private let cornerRadius: CGFloat
    
    // MARK: - Init
    
    public init(
        value: Binding<Double>,
        tintColor: Color = .white,
        height: CGFloat = 8,
        cornerRadius: CGFloat? = nil
    ) {
        self._value = value
        self.tintColor = tintColor
        self.height = height
        self.cornerRadius = cornerRadius ?? height / 2
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 背景轨道
                Capsule()
                    .fill(.clear)
                    .liquidGlass(config: .subtle, cornerRadius: cornerRadius)
                
                // 填充
                Capsule()
                    .fill(tintColor)
                    .frame(width: max(height, geo.size.width * value))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = gesture.location.x / geo.size.width
                        value = max(0, min(1, newValue))
                    }
            )
        }
        .frame(height: height)
    }
}
