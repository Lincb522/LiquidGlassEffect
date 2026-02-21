//
//  LiquidGlassProgress.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃进度条
//

import SwiftUI

// MARK: - Linear Progress

/// 液态玻璃线性进度条
///
/// ```swift
/// LiquidGlassProgress(value: 0.7, tintColor: .blue)
/// ```
public struct LiquidGlassProgress: View {
    
    // MARK: - Properties
    
    private let value: Double
    private let tintColor: Color
    private let height: CGFloat
    private let config: LiquidGlassConfig
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
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

// MARK: - Circular Progress

/// 液态玻璃圆形进度
///
/// ```swift
/// LiquidGlassCircularProgress(value: 0.7, tintColor: .blue)
/// ```
public struct LiquidGlassCircularProgress: View {
    
    // MARK: - Properties
    
    private let value: Double
    private let tintColor: Color
    private let lineWidth: CGFloat
    private let size: CGFloat
    private let config: LiquidGlassConfig
    
    // MARK: - Init
    
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
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // 背景圆
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

// MARK: - Indeterminate Progress

/// 液态玻璃不确定进度指示器
public struct LiquidGlassIndeterminateProgress: View {
    
    // MARK: - Properties
    
    private let tintColor: Color
    private let size: CGFloat
    
    @State private var isAnimating = false
    
    // MARK: - Init
    
    public init(
        tintColor: Color = .white,
        size: CGFloat = 40
    ) {
        self.tintColor = tintColor
        self.size = size
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .liquidGlass(config: .subtle, cornerRadius: size / 2)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(tintColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .padding(6)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
