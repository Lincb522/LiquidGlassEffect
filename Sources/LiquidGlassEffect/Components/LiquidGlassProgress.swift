//
//  LiquidGlassProgress.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃进度条
//

import SwiftUI

/// 液态玻璃进度条
public struct LiquidGlassProgress: View {
    
    let value: Double
    var tintColor: Color
    var height: CGFloat
    var config: LiquidGlassConfig
    
    public init(
        value: Double,
        tintColor: Color = .white,
        height: CGFloat = 8,
        config: LiquidGlassConfig = .subtle
    ) {
        self.value = min(max(value, 0), 1)
        self.tintColor = tintColor
        self.height = height
        self.config = config
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 液态玻璃背景轨道
                Capsule()
                    .fill(.clear)
                    .liquidGlass(config: config, cornerRadius: height / 2)
                
                // 进度填充
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tintColor, tintColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geometry.size.width * value))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

/// 液态玻璃圆形进度
public struct LiquidGlassCircularProgress: View {
    
    let value: Double
    var tintColor: Color
    var lineWidth: CGFloat
    var size: CGFloat
    var config: LiquidGlassConfig
    
    public init(
        value: Double,
        tintColor: Color = .white,
        lineWidth: CGFloat = 6,
        size: CGFloat = 60,
        config: LiquidGlassConfig = .subtle
    ) {
        self.value = min(max(value, 0), 1)
        self.tintColor = tintColor
        self.lineWidth = lineWidth
        self.size = size
        self.config = config
    }
    
    public var body: some View {
        ZStack {
            // 液态玻璃背景圆
            Circle()
                .fill(.clear)
                .liquidGlass(config: config, cornerRadius: size / 2)
            
            // 背景轨道
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: lineWidth)
                .padding(lineWidth / 2 + 4)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    tintColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(lineWidth / 2 + 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
        }
        .frame(width: size, height: size)
    }
}
