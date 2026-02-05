//
//  BackdropView.swift
//  LiquidGlassEffect
//
//  背景捕获视图（使用私有 API）
//

import UIKit

/// 使用 CABackdropLayer 捕获背后内容的视图
///
/// `CABackdropLayer` 是 Apple 的私有 API，用于捕获视图层级中位于该视图下方的内容。
/// 这是实现实时背景模糊效果的关键组件。
///
/// - Warning: 使用私有 API 可能导致 App Store 审核问题，但目前广泛使用且未被拒绝。
public final class BackdropView: UIView {
    
    // MARK: - Layer Class
    
    public override class var layerClass: AnyClass {
        NSClassFromString("CABackdropLayer") ?? CALayer.self
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
        
        // 配置 CABackdropLayer 属性
        layer.setValue(false, forKey: "layerUsesCoreImageFilters")
        layer.setValue(true, forKey: "windowServerAware")
        layer.setValue(UUID().uuidString, forKey: "groupName")
    }
}
