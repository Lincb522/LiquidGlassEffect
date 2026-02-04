//
//  BackdropView.swift
//  LiquidGlassEffect
//
//  背景捕获视图（使用私有 API）
//

import UIKit

/// 使用 CABackdropLayer 捕获背后内容的视图
public final class BackdropView: UIView {
    
    override public class var layerClass: AnyClass {
        NSClassFromString("CABackdropLayer") ?? CALayer.self
    }
    
    public init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.setValue(false, forKey: "layerUsesCoreImageFilters")
        layer.setValue(true, forKey: "windowServerAware")
        layer.setValue(UUID().uuidString, forKey: "groupName")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 阴影视图
public final class ShadowView: UIView {
    
    public init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        layer.compositingFilter = "multiplyBlendMode"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let shadowRadius: CGFloat = 3.5
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: -1, dy: -shadowRadius / 2),
            cornerRadius: bounds.height / 2
        )
        let innerPill = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0, dy: shadowRadius / 2),
            cornerRadius: bounds.height / 2
        ).reversing()
        path.append(innerPill)
        
        layer.shadowPath = path.cgPath
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: shadowRadius + 2)
    }
}
