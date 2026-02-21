//
//  ShadowView.swift
//  LiquidGlassEffect
//
//  液态玻璃阴影视图
//

import UIKit

/// 液态玻璃阴影视图
///
/// 使用 `multiplyBlendMode` 混合模式创建柔和的内阴影效果。
public final class ShadowView: UIView {
    
    // MARK: - Configuration
    
    /// 阴影半径
    public var shadowRadius: CGFloat = 3.5 {
        didSet { setNeedsLayout() }
    }
    
    /// 阴影不透明度
    public var shadowOpacityValue: Float = 0.2 {
        didSet { layer.shadowOpacity = shadowOpacityValue }
    }
    
    /// 阴影垂直偏移
    public var shadowVerticalOffset: CGFloat = 2 {
        didSet { setNeedsLayout() }
    }
    
    // MARK: - Init
    
    public init() {
        super.init(frame: .zero)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        layer.compositingFilter = "multiplyBlendMode"
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }
    
    private func updateShadowPath() {
        let cornerRadius = bounds.height / 2
        
        // 外部路径
        let outerPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: -1, dy: -shadowRadius / 2),
            cornerRadius: cornerRadius
        )
        
        // 内部路径（反向，创建环形）
        let innerPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0, dy: shadowRadius / 2),
            cornerRadius: cornerRadius
        ).reversing()
        
        outerPath.append(innerPath)
        
        layer.shadowPath = outerPath.cgPath
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacityValue
        layer.shadowOffset = CGSize(width: 0, height: shadowRadius + shadowVerticalOffset)
    }
}
