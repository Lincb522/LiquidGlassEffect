//
//  LiquidLensView.swift
//  LiquidGlassEffect
//
//  动态镜头视图（带加速度变形动画）
//

import UIKit

/// 动态镜头视图协议
@MainActor @objc public protocol AnyLiquidLensView {
    init()
    init(restingBackground backgroundView: UIView?)
    var restingBackgroundColor: UIColor? { get set }
    func setLiftedContainerView(_ containerView: UIView?)
    func setLiftedContentView(_ contentView: UIView?)
    func setOverridePunchoutView(_ punchoutView: UIView?)
    func setLifted(_ lifted: Bool, animated: Bool, alongsideAnimations: (() -> Void)?, completion: ((Bool) -> Void)?)
    func setLiftedContentMode(_ contentMode: Int)
    func setStyle(_ style: Int)
    func setWarpsContentBelow(_ warpsContentBelow: Bool)
}

public typealias UILiquidLensView = UIView & AnyLiquidLensView

/// 动态镜头视图 - 在静止药丸状态和激活液态玻璃状态之间变形
public final class LiquidLensView: UIView, AnyLiquidLensView {
    
    // MARK: - Constants
    
    private let accelerationWindowDuration: TimeInterval = 0.3
    private let accelerationScaleCoefficient: CGFloat = 0.00005
    private let maxScaleDeviation: CGFloat = 0.3
    
    // MARK: - State
    
    private var positionHistory: [(position: CGPoint, timestamp: TimeInterval)] = []
    private var displayLink: CADisplayLink?
    private weak var liftedContainerView: UIView?
    private weak var liftedContentView: UIView?
    private weak var overridePunchoutView: UIView?
    private var isLifted = false
    private var liftedContentMode: Int = 0
    private var style: Int = 0
    private var warpsContentBelow: Bool = false
    
    private let restingPillView = UIView()
    private let liquidGlassView = LiquidGlassView(.lens)
    
    // MARK: - Public
    
    public var restingBackgroundColor: UIColor? {
        get { restingPillView.backgroundColor }
        set { restingPillView.backgroundColor = newValue }
    }
    
    // MARK: - Init
    
    public convenience init() {
        self.init(restingBackground: nil)
    }
    
    public init(restingBackground backgroundView: UIView?) {
        super.init(frame: .zero)
        setupViews()
        if let backgroundView { restingPillView.addSubview(backgroundView) }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        clipsToBounds = false
        
        restingPillView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        restingPillView.isUserInteractionEnabled = false
        addSubview(restingPillView)
        
        liquidGlassView.alpha = 0
        liquidGlassView.isUserInteractionEnabled = false
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        restingPillView.frame = bounds
        restingPillView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
    
    // MARK: - Protocol
    
    public func setLiftedContainerView(_ containerView: UIView?) { liftedContainerView = containerView }
    public func setLiftedContentView(_ contentView: UIView?) { liftedContentView = contentView }
    public func setOverridePunchoutView(_ punchoutView: UIView?) { overridePunchoutView = punchoutView }
    public func setLiftedContentMode(_ contentMode: Int) { self.liftedContentMode = contentMode }
    public func setStyle(_ style: Int) { self.style = style }
    public func setWarpsContentBelow(_ warpsContentBelow: Bool) { self.warpsContentBelow = warpsContentBelow }
    
    public func setLifted(_ lifted: Bool, animated: Bool, alongsideAnimations: (() -> Void)?, completion: ((Bool) -> Void)?) {
        guard isLifted != lifted else { completion?(true); return }
        isLifted = lifted
        
        if lifted {
            liftUp(animated: animated, alongsideAnimations: alongsideAnimations, completion: completion)
        } else {
            liftDown(animated: animated, alongsideAnimations: alongsideAnimations, completion: completion)
        }
    }
    
    // MARK: - Animation
    
    private func liftUp(animated: Bool, alongsideAnimations: (() -> Void)?, completion: ((Bool) -> Void)?) {
        liquidGlassView.frame = bounds
        liquidGlassView.layer.cornerRadius = restingPillView.layer.cornerRadius
        liquidGlassView.alpha = 0
        addSubview(liquidGlassView)
        startPositionTracking()
        
        let animations = {
            self.restingPillView.alpha = 0
            self.liquidGlassView.alpha = 1
            alongsideAnimations?()
        }
        
        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: animations) { completion?($0) }
        } else {
            animations()
            completion?(true)
        }
    }
    
    private func liftDown(animated: Bool, alongsideAnimations: (() -> Void)?, completion: ((Bool) -> Void)?) {
        stopPositionTracking()
        restingPillView.alpha = 0
        
        let animations = {
            self.restingPillView.alpha = 1
            self.liquidGlassView.alpha = 0
            alongsideAnimations?()
        }
        
        let done: (Bool) -> Void = { finished in
            guard finished else { completion?(finished); return }
            self.liquidGlassView.removeFromSuperview()
            self.liquidGlassView.alpha = 1
            completion?(finished)
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: animations, completion: done)
        } else {
            animations()
            done(true)
        }
    }
    
    // MARK: - Position Tracking
    
    private func startPositionTracking() {
        positionHistory.removeAll()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePositionTracking))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopPositionTracking() {
        displayLink?.invalidate()
        displayLink = nil
        positionHistory.removeAll()
        liquidGlassView.frame = bounds
    }
    
    @objc private func updatePositionTracking() {
        let currentTime = CACurrentMediaTime()
        let currentPosition = layer.position
        
        positionHistory.append((position: currentPosition, timestamp: currentTime))
        positionHistory.removeAll { $0.timestamp < currentTime - accelerationWindowDuration }
        
        let acceleration = calculateAverageAcceleration()
        applyAccelerationSize(acceleration)
    }
    
    private func calculateAverageAcceleration() -> CGFloat {
        guard positionHistory.count >= 3 else { return 0 }
        
        var velocities: [(velocity: CGPoint, timestamp: TimeInterval)] = []
        for i in 1..<positionHistory.count {
            let prev = positionHistory[i - 1]
            let curr = positionHistory[i]
            let dt = curr.timestamp - prev.timestamp
            guard dt > 0 else { continue }
            
            let velocity = CGPoint(
                x: (curr.position.x - prev.position.x) / dt,
                y: (curr.position.y - prev.position.y) / dt
            )
            velocities.append((velocity: velocity, timestamp: (prev.timestamp + curr.timestamp) / 2))
        }
        
        guard velocities.count >= 2 else { return 0 }
        
        var totalAccX: CGFloat = 0, totalAccY: CGFloat = 0, count: CGFloat = 0
        
        for i in 1..<velocities.count {
            let prev = velocities[i - 1]
            let curr = velocities[i]
            let dt = curr.timestamp - prev.timestamp
            guard dt > 0 else { continue }
            
            totalAccX += (curr.velocity.x - prev.velocity.x) / dt
            totalAccY += (curr.velocity.y - prev.velocity.y) / dt
            count += 1
        }
        
        guard count > 0 else { return 0 }
        return (totalAccX - totalAccY) / count
    }
    
    private func applyAccelerationSize(_ acceleration: CGFloat) {
        let scaleFactor = acceleration * accelerationScaleCoefficient
        let clampedScale = max(-maxScaleDeviation, min(maxScaleDeviation, scaleFactor))
        
        let scaleX = 1 + clampedScale
        let scaleY = 1 - clampedScale
        
        let newWidth = bounds.width * scaleX
        let newHeight = bounds.height * scaleY
        
        liquidGlassView.frame = CGRect(
            x: (bounds.width - newWidth) / 2,
            y: (bounds.height - newHeight) / 2,
            width: newWidth,
            height: newHeight
        )
    }
}
