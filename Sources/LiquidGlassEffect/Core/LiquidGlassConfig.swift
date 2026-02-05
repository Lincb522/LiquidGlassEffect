//
//  LiquidGlassConfig.swift
//  LiquidGlassEffect
//
//  液态玻璃效果配置
//  Based on LiquidGlassKit by Alexey Demin (DnV1eX)
//  https://github.com/DnV1eX/LiquidGlassKit
//

import UIKit

// MARK: - Config

/// 液态玻璃效果配置
///
/// 包含渲染参数和纹理捕获设置。
/// 使用预设配置或自定义参数创建不同风格的液态玻璃效果。
public struct LiquidGlassConfig {
    
    /// 最大矩形数量（与 shader 中的 `maxRectangles` 一致）
    public static let maxRectangles = 16
    
    /// Shader 参数
    public let uniforms: LiquidGlassUniforms
    
    /// 背景纹理尺寸系数（相对于视图尺寸）
    ///
    /// 值越大，捕获的背景区域越大，边缘效果越好，但性能开销也越大。
    /// 推荐范围：1.0 - 1.2
    public let textureSizeCoefficient: Double
    
    /// 背景纹理缩放系数
    ///
    /// 值越小，纹理分辨率越低，性能越好，但清晰度下降。
    /// 推荐范围：0.5 - 1.0
    public let textureScaleCoefficient: Double
    
    /// 背景模糊半径
    ///
    /// 0 = 无模糊，值越大模糊越强。
    /// 推荐范围：0 - 20
    public let blurRadius: Double
    
    /// 是否显示阴影
    public let shadowOverlay: Bool
    
    // MARK: - Init
    
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
    
    /// 标准效果
    ///
    /// 适用于卡片、面板等中等尺寸组件。
    static let regular = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            glareIntensity: 0.1
        ),
        shadowOverlay: true
    )
    
    /// 镜头效果
    ///
    /// 适用于 TabBar 指示器、按钮高亮等需要聚焦效果的场景。
    static let lens = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            glareIntensity: 0.1
        ),
        shadowOverlay: true
    )
    
    /// 轻微效果
    ///
    /// 最小折射，适用于不需要强烈视觉效果的场景。
    static let subtle = Self(
        uniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 10,
            glareIntensity: 0.05
        ),
        shadowOverlay: true
    )
    
    /// 缩略图/小组件效果
    ///
    /// 适用于 TabBar 选中气泡、小按钮等小尺寸组件。
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
