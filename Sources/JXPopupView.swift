//
//  JXPopupView.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

public protocol JXPopupViewAnimationProtocol: AnyObject {
    /// 初始化配置动画驱动器
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - containerView: 展示弹框的视图
    /// - Returns: void
    func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView)

    /// 处理展示动画
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - animated: 是否需要动画
    ///   - completion: 动画完成后的回调
    /// - Returns: void
    func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping ()->())

    /// 处理消失动画
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - animated: 是否需要动画
    ///   - completion: 动画完成后的回调
    func dismiss(contentView: UIView, backgroundView: JXBackgroundView,animated: Bool, completion: @escaping ()->())
}

public enum JXPopupViewBackgroundStyle {
    case solidColor
    case blur
}


/// 一个轻量级的自定义视图弹框框架，主要提供动画、背景的灵活配置，功能简单却强大
/// 通过面对协议JXPopupViewAnimationProtocol，实现对动画的灵活配置
/// 通过JXBackgroundView对背景进行自定义配置
public class JXPopupView: UIView {
    /*
     举个例子
     /////////////////////
     ///////////////////B/
     ////-------------////
     ///|             |///
     ///|             |///
     ///|             |///
     ///|             |///
     ///|             |///
     ///|      A      |///
     ///|             |///
     ///|             |///
     ///|             |///
     ///|_____________|///
     /////////////////////
     /////////////////////

     - isDismissible  为YES时，点击区域B可以消失（前提是isPenetrable为false）
     - isInteractive  为YES时，点击区域A可以触发contentView上的交互操作
     - isPenetrable   为YES时，将会忽略区域B的交互操作
     */
    public var isDismissible = false {
        didSet {
            backgroundView.isUserInteractionEnabled = isDismissible
        }
    }
    public var isInteractive = true
    public var isPenetrable = false
    public let backgroundView: JXBackgroundView
    public var willDispalyCallback: (()->())?
    public var didDispalyCallback: (()->())?
    public var willDismissCallback: (()->())?
    public var didDismissCallback: (()->())?

    weak var containerView: UIView!
    let contentView: UIView
    let animator: JXPopupViewAnimationProtocol
    var isAnimating = false

    deinit {
        willDispalyCallback = nil
        didDispalyCallback = nil
        willDismissCallback = nil
        didDismissCallback = nil
    }


    /// 指定的s初始化器
    ///
    /// - Parameters:
    ///   - containerView: 展示弹框的视图，可以是window、vc.view、自定义视图等
    ///   - contentView: 自定义的弹框视图
    ///   - animator: 遵从协议JXPopupViewAnimationProtocol的动画驱动器
    public init(containerView: UIView, contentView: UIView, animator: JXPopupViewAnimationProtocol) {
        self.containerView = containerView
        self.contentView = contentView
        self.animator = animator
        backgroundView = JXBackgroundView(frame: CGRect.zero)
        
        super.init(frame: containerView.bounds)

        backgroundView.isUserInteractionEnabled = isDismissible
        backgroundView.addTarget(self, action: #selector(backgroundViewClicked), for: UIControl.Event.touchUpInside)
        addSubview(backgroundView)
        addSubview(contentView)

        animator.setup(contentView: contentView, backgroundView: backgroundView, containerView: containerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointInContent = convert(point, to: contentView)
        let isPointInContent = contentView.bounds.contains(pointInContent)
        if isPointInContent {
            if isInteractive {
                return super.hitTest(point, with: event)
            }else {
                return nil
            }
        }else {
            if !isPenetrable {
                return super.hitTest(point, with: event)
            }else {
                return nil
            }
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = self.bounds
    }

    public func display(animated: Bool, completion: (()->())?) {
        if isAnimating {
            return
        }
        isAnimating = true
        containerView.addSubview(self)

        willDispalyCallback?()
        animator.display(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            completion?()
            self.isAnimating = false
            self.didDispalyCallback?()
        })
    }

    public func dismiss(animated: Bool, completion: (()->())?) {
        if isAnimating {
            return
        }
        isAnimating = true
        willDismissCallback?()
        animator.dismiss(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            self.removeFromSuperview()
            completion?()
            self.isAnimating = false
            self.didDismissCallback?()
        })
    }

    @objc func backgroundViewClicked() {
        dismiss(animated: true, completion: nil)
    }
}

public extension UIView {

    /// 便利获取JXPopupView
    var jx_popupView: JXPopupView? {
        if self.superview?.isKind(of: JXPopupView.classForCoder()) == true {
            return self.superview as? JXPopupView
        }
        return nil
    }
}

public class JXBackgroundView: UIControl {
    public var style = JXPopupViewBackgroundStyle.solidColor {
        didSet {
            refreshBackgroundStyle()
        }
    }
    public var blurEffectStyle = UIBlurEffect.Style.dark {
        didSet {
            refreshBackgroundStyle()
        }
    }
    /// 无论style是什么值，color都会生效。如果你使用blur的时候，觉得叠加上该color过于黑暗时，可以置为clearColor。
    public var color = UIColor.black.withAlphaComponent(0.3) {
        didSet {
            backgroundColor = color
        }
    }
    var effectView: UIVisualEffectView?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        refreshBackgroundStyle()
        backgroundColor = color
        layer.allowsGroupOpacity = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == effectView {
            //将event交给backgroundView处理
            return self
        }
        return view
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        effectView?.frame = self.bounds
    }

    func refreshBackgroundStyle() {
        if style == .solidColor {
            effectView?.removeFromSuperview()
            effectView = nil
        }else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffectStyle))
            addSubview(effectView!)
        }
    }
}

open class JXPopupViewBaseAnimator: JXPopupViewAnimationProtocol {
    open var displayDuration: TimeInterval = 0.25
    open var displayAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    /// 展示动画的配置block
    open var displayAnimateBlock: (()->())?

    open var dismissDuration: TimeInterval = 0.25
    open var dismissAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    /// 消失动画的配置block
    open var dismissAnimateBlock: (()->())?

    public init() {
    }

    open func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
    }

    open func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, options: displayAnimationOptions, animations: {
                self.displayAnimateBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.displayAnimateBlock?()
            completion()
        }
    }

    open func dismiss(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, options: dismissAnimationOptions, animations: {
                self.dismissAnimateBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.dismissAnimateBlock?()
            completion()
        }
    }
}

open class JXPopupViewLeftwardAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = containerView.bounds.size.width
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class JXPopupViewRightwardAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = -contentView.bounds.size.width
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class JXPopupViewUpwardAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = containerView.bounds.size.height
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class JXPopupViewDownwardAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = -contentView.bounds.size.height
        let sourceRect = frame
        let targetRect = contentView.frame
        contentView.frame = sourceRect
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.frame = sourceRect
            backgroundView.alpha = 0
        }
    }
}

open class JXPopupViewFadeInOutAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        contentView.alpha = 0
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.alpha = 1
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.alpha = 0
            backgroundView.alpha = 0
        }
    }
}

open class JXPopupViewZoomInOutAnimator: JXPopupViewBaseAnimator {
    open override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        displayAnimateBlock = {
            contentView.alpha = 1
            contentView.transform = .identity
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.alpha = 0
            contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            backgroundView.alpha = 0
        }
    }
}
