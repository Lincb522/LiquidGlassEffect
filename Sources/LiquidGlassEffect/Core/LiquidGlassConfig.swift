//
//  LiquidGlassConfig.swift
//  LiquidGlassEffect
//
//  液态玻璃效果配置
//  Based on LiquidGlassKit by Alexey Demin (DnV1eX)
//  https://github.com/DnV1eX/LiquidGlassKit
//

import UIKit
import simd

// MARK: - Shader Uniforms

/// Shader 参数结构体（与 Metal shader 完全匹配）
public struct LiquidGlassUniforms {
    public var resolution: SIMD2<Float> = .zero
    public var contentsScale: Float = .zero
    public var touchPoint: SIMD2<Float> = .zero
    public var shapeMergeSmoothness: Float = .zero
    public var cornerRadius: Float = .zero
    public var cornerRoundnessExponent: Float = 2
    public var materialTint: SIMD4<Float> = .zero
    public var glassThickness: Float
    public var refractiveIndex: Float
    public var dispersionStrength: Float
    public var fresnelDistanceRange: Float
    public var fresnelIntensity: Float
    public var fresnelEdgeSharpness: Float
    public var glareDistanceRange: Float
    public var glareAngleConvergence: Float
    public var glareOppositeSideBias: Float
    public var glareIntensity: Float
    public var glareEdgeSharpness: Float
    public var glareDirectionOffset: Float
    public var rectangleCount: Int32 = .zero
    public var rectangles: (
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>
    ) = (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
         .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero)
    
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

// MARK: - Config

/// 液态玻璃效果配置
public struct LiquidGlassConfig {
    
    /// 最大矩形数量
    public static let maxRectangles = 16
    
    /// Shader 参数
    public let uniforms: LiquidGlassUniforms
    
    /// 背景纹理尺寸系数
    public let textureSizeCoefficient: Double
    
    /// 背景纹理缩放系数
    public let textureScaleCoefficient: Double
    
    /// 背景模糊半径
    public let blurRadius: Double
    
    /// 是否显示阴影
    public let shadowOverlay: Bool
    
    public init(
        uniforms: LiquidGlassUniforms = .init(),
        textureSizeCoefficient: Double = 1.1,
        textureScaleCoefficient: Double = 0.8,
        blurRadius: Double = 0,
        shadowOverlay: Bool = true
    ) {
        self.uniforms = uniforms
        self.textureSizeCoefficient = textureSizeCoefficient
        self.textureScaleCoefficient = textureScaleCoefficient
        self.blurRadius = blurRadius
        self.shadowOverlay = shadowOverlay
    }
}

// MARK: - Presets

public extension LiquidGlassConfig {
    
    /// 标准效果 - 适用于卡片、面板
    static let regular = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            glareIntensity: 0.1
        ),
        shadowOverlay: true
    )
    
    /// 镜头效果 - 适用于 TabBar 指示器、按钮高亮
    static let lens = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            glareIntensity: 0.1
        ),
        shadowOverlay: true
    )
    
    /// 轻微效果 - 最小折射
    static let subtle = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 10,
            glareIntensity: 0.05
        ),
        shadowOverlay: true
    )
    
    /// 缩略图/小组件效果 - 适用于 TabBar 选中气泡、小按钮
    /// - Parameter magnification: 放大倍数，默认 1
    static func thumb(magnification: Double = 1) -> Self {
        Self(
            uniforms: .init(
                glassThickness: 10,
                refractiveIndex: 1.11,
                dispersionStrength: 5,
                fresnelDistanceRange: 70,
                fresnelIntensity: 0,
                fresnelEdgeSharpness: 0,
                glareDistanceRange: 30,
                glareAngleConvergence: 0,
                glareOppositeSideBias: 0,
                glareIntensity: 0.01,
                glareEdgeSharpness: -0.2,
                glareDirectionOffset: .pi * 0.9
            ),
            textureSizeCoefficient: 1 / magnification,
            textureScaleCoefficient: magnification,
            blurRadius: 0,
            shadowOverlay: true
        )
    }
}
