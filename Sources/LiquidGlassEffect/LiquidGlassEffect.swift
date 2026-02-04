//
//  LiquidGlassEffect.swift
//  LiquidGlassEffect
//
//  iOS 26 风格液态玻璃效果库
//  Based on LiquidGlassKit by Alexey Demin (DnV1eX)
//  https://github.com/DnV1eX/LiquidGlassKit
//
//  支持 iOS 15+
//

import Foundation

/// LiquidGlassEffect 库信息
public enum LiquidGlassEffectInfo {
    /// 库版本
    public static let version = "1.0.0"
    
    /// 最低 iOS 版本
    public static let minimumIOSVersion = "15.0"
    
    /// 致谢
    public static let credits = "https://github.com/DnV1eX/LiquidGlassKit"
}

/*
 Public API:
 
 ## Core
 - LiquidGlassConfig          配置
 - LiquidGlassUniforms        Shader 参数
 - LiquidGlassView            MTKView 实现
 - LiquidGlassRenderer        渲染器
 - LiquidGlassEngine          性能引擎
 - LiquidGlassPerformanceMode 性能模式
 
 ## SwiftUI
 - LiquidGlassMetalView       UIViewRepresentable
 - View.liquidGlass()         修饰器
 - View.liquidGlassLens()     镜头效果修饰器
 - View.liquidGlassSubtle()   轻微效果修饰器
 
 ## Components
 - LiquidGlassButton          按钮
 - LiquidGlassIconButton      图标按钮
 - LiquidGlassCard            卡片
 - LiquidGlassFloatingBar     悬浮栏
 - LiquidGlassTabBar          TabBar
 - LiquidGlassLabeledTabBar   带标签 TabBar
 - LiquidGlassPillTabBar      药丸形 TabBar
 - LiquidGlassContainer       容器
 - LiquidGlassSlider          滑块
 - LiquidGlassTextField       输入框
 - LiquidGlassToggle          开关
 - LiquidGlassTag             标签
 - LiquidGlassNotification    通知
 - LiquidGlassProgress        线性进度条
 - LiquidGlassCircularProgress 圆形进度
 - LiquidLensView             镜头视图
 */
