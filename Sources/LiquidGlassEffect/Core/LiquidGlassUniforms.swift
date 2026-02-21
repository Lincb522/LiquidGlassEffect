//
//  LiquidGlassUniforms.swift
//  LiquidGlassEffect
//
//  Shader 参数结构体（与 Metal shader 完全匹配）
//  Based on LiquidGlassKit by Alexey Demin (DnV1eX)
//

import simd

// MARK: - Shader Uniforms

/// Shader 参数结构体
/// 
/// 该结构体的内存布局必须与 Metal shader 中的 `ShaderUniforms` 完全一致。
/// 任何修改都需要同步更新 `LiquidGlassShader.metal`。
public struct LiquidGlassUniforms {
    
    // MARK: - 基础参数
    
    /// 渲染分辨率（像素）
    public var resolution: SIMD2<Float> = .zero
    
    /// 屏幕缩放系数
    public var contentsScale: Float = .zero
    
    /// 触摸点位置（用于交互效果）
    public var touchPoint: SIMD2<Float> = .zero
    
    /// 形状合并平滑度
    public var shapeMergeSmoothness: Float = .zero
    
    /// 圆角半径
    public var cornerRadius: Float = .zero
    
    /// 圆角曲率指数（2 = 标准圆角，更高 = 更方）
    public var cornerRoundnessExponent: Float = 2
    
    // MARK: - 材质参数
    
    /// 材质着色（RGBA，A 控制混合强度）
    public var materialTint: SIMD4<Float> = .zero
    
    // MARK: - 玻璃物理参数
    
    /// 玻璃厚度（影响折射深度）
    public var glassThickness: Float
    
    /// 折射率（1.0 = 空气，1.5 = 玻璃）
    public var refractiveIndex: Float
    
    /// 色散强度（彩虹边缘效果）
    public var dispersionStrength: Float
    
    // MARK: - 菲涅尔效果参数
    
    /// 菲涅尔距离范围
    public var fresnelDistanceRange: Float
    
    /// 菲涅尔强度
    public var fresnelIntensity: Float
    
    /// 菲涅尔边缘锐度
    public var fresnelEdgeSharpness: Float
    
    // MARK: - 眩光效果参数
    
    /// 眩光距离范围
    public var glareDistanceRange: Float
    
    /// 眩光角度收敛
    public var glareAngleConvergence: Float
    
    /// 眩光对侧偏移
    public var glareOppositeSideBias: Float
    
    /// 眩光强度
    public var glareIntensity: Float
    
    /// 眩光边缘锐度
    public var glareEdgeSharpness: Float
    
    /// 眩光方向偏移
    public var glareDirectionOffset: Float
    
    // MARK: - UV 映射（共享纹理用）
    
    /// UV 偏移
    public var uvOffset: SIMD2<Float> = .zero
    
    /// UV 缩放
    public var uvScale: SIMD2<Float> = SIMD2<Float>(1.0, 1.0)
    
    // MARK: - 矩形区域
    
    /// 矩形数量
    public var rectangleCount: Int32 = .zero
    
    /// 矩形数组（最多 16 个）
    public var rectangles: (
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>
    ) = (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
         .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero)
    
    // MARK: - Init
    
    public init(
        glassThickness: Float = 6,
        refractiveIndex: Float = 1.1,
        dispersionStrength: Float = 15,
        fresnelDistanceRange: Float = 70,
        fresnelIntensity: Float = 0,
        fresnelEdgeSharpness: Float = 0,
        glareDistanceRange: Float = 30,
        glareAngleConvergence: Float = 0.1,
        glareOppositeSideBias: Float = 1,
        glareIntensity: Float = 0.1,
        glareEdgeSharpness: Float = -0.1,
        glareDirectionOffset: Float = -.pi / 4
    ) {
        self.glassThickness = glassThickness
        self.refractiveIndex = refractiveIndex
        self.dispersionStrength = dispersionStrength
        self.fresnelDistanceRange = fresnelDistanceRange
        self.fresnelIntensity = fresnelIntensity
        self.fresnelEdgeSharpness = fresnelEdgeSharpness
        self.glareDistanceRange = glareDistanceRange
        self.glareAngleConvergence = glareAngleConvergence
        self.glareOppositeSideBias = glareOppositeSideBias
        self.glareIntensity = glareIntensity
        self.glareEdgeSharpness = glareEdgeSharpness
        self.glareDirectionOffset = glareDirectionOffset
    }
}
