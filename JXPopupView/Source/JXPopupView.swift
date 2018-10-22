//
//  JXPopupView.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

public protocol JXPopupViewAnimationProtocol: AnyObject {
    func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView)
    func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping ()->())
    func dismiss(contentView: UIView, backgroundView: JXBackgroundView,animated: Bool, completion: @escaping ()->())
}

public enum JXPopupViewBackgroundStyle {
    case solidColor
    case blur
}

public class JXPopupView: UIView {
    public let backgroundView: JXBackgroundView
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

     - dismissible  为YES时，点击区域B可以消失
     - penetrable   为YES时，将会忽略区域B的交互操作（如果penetrable为true，dismissible为true，此时dismissible将失效，无法点击区域B消失）
     */
    public var dismissable = false {
        didSet {
            backgroundView.isUserInteractionEnabled = dismissable
        }
    }
    public var penetrable = false
    public var willDispalyCallback: (()->())?
    public var didDispalyCallback: (()->())?
    public var willDismissCallback: (()->())?
    public var didDismissCallback: (()->())?

    let containerView: UIView
    let contentView: UIView
    let animator: JXPopupViewAnimationProtocol

    deinit {
        willDispalyCallback = nil
        didDispalyCallback = nil
        willDismissCallback = nil
        didDismissCallback = nil
    }

    public init(containerView: UIView, contentView: UIView, animator: JXPopupViewAnimationProtocol) {
        self.containerView = containerView
        self.contentView = contentView
        self.animator = animator
        backgroundView = JXBackgroundView(frame: CGRect.zero)

        super.init(frame: containerView.bounds)

        backgroundView.isUserInteractionEnabled = false
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
        if penetrable && !isPointInContent {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = self.bounds
    }

    public func display(animated: Bool, completion: (()->())?) {
        containerView.addSubview(self)

        willDispalyCallback?()
        animator.display(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            completion?()
            self.didDispalyCallback?()
        })
    }

    public func dismiss(animated: Bool, completion: (()->())?) {
        willDismissCallback?()
        animator.dismiss(contentView: contentView, backgroundView: backgroundView, animated: animated, completion: {
            self.removeFromSuperview()
            completion?()
            self.didDismissCallback?()
        })
    }

    @objc func backgroundViewClicked() {
        dismiss(animated: true, completion: nil)
    }
}

extension UIView {
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == effectView {
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

public class JXPopupViewBaseAnimator: JXPopupViewAnimationProtocol {
    public var displayDamping: CGFloat = 1
    public var displayInitialSpringVelocaity: CGFloat = 0
    public var displayDuration: TimeInterval = 0.25
    public var displayAnimationOptions = UIView.AnimationOptions.init(rawValue: 7 << 16)
    public var dismissDamping: CGFloat = 1
    public var dismissInitialSpringVelocaity: CGFloat = 0
    public var dismissDuration: TimeInterval = 0.25
    public var dismissAnimationOptions = UIView.AnimationOptions.curveEaseIn
    var targetRect = CGRect.zero
    var sourceRect = CGRect.zero

    public func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
    }

    public func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displayDamping, initialSpringVelocity: displayInitialSpringVelocaity, options: displayAnimationOptions, animations: {
                contentView.frame = self.targetRect
                backgroundView.alpha = 1
            }) { (finished) in
                completion()
            }
        }else {
            contentView.frame = targetRect
            completion()
        }
    }

    public func dismiss(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, usingSpringWithDamping: dismissDamping, initialSpringVelocity: dismissInitialSpringVelocaity, options: dismissAnimationOptions, animations: {
                contentView.frame = self.sourceRect
                backgroundView.alpha = 0
            }) { (finished) in
                completion()
            }
        }else {
            contentView.frame = sourceRect
            completion()
        }
    }
}

public class JXPopupViewLeftwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = containerView.bounds.size.width
        sourceRect = frame
        targetRect = contentView.frame
        contentView.frame = sourceRect

        backgroundView.alpha = 0
    }
}

public class JXPopupViewRightwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = -contentView.bounds.size.width
        sourceRect = frame
        targetRect = contentView.frame
        contentView.frame = sourceRect

        backgroundView.alpha = 0
    }
}

public class JXPopupViewUpwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = containerView.bounds.size.height
        sourceRect = frame
        targetRect = contentView.frame
        contentView.frame = sourceRect

        backgroundView.alpha = 0
    }
}

public class JXPopupViewDownwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.y = -contentView.bounds.size.height
        sourceRect = frame
        targetRect = contentView.frame
        contentView.frame = sourceRect

        backgroundView.alpha = 0
    }
}

public class JXPopupViewFadeInOutAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        contentView.alpha = 0
        backgroundView.alpha = 0
    }

    public override func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displayDamping, initialSpringVelocity: displayInitialSpringVelocaity, options: displayAnimationOptions, animations: {
                contentView.alpha = 1
                backgroundView.alpha = 1
            }) { (finished) in
                completion()
            }
        }else {
            contentView.alpha = 1
            completion()
        }
    }

    public override func dismiss(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, usingSpringWithDamping: dismissDamping, initialSpringVelocity: dismissInitialSpringVelocaity, options: dismissAnimationOptions, animations: {
                contentView.alpha = 0
                backgroundView.alpha = 0
            }) { (finished) in
                completion()
            }
        }else {
            contentView.alpha = 0
            completion()
        }
    }
}

public class JXPopupViewZoomInOutAnimator: JXPopupViewBaseAnimator {
    let smallTransform = CGAffineTransform(scaleX: 0.3, y: 0.3)

    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = smallTransform
    }

    public override func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displayDamping, initialSpringVelocity: displayInitialSpringVelocaity, options: displayAnimationOptions, animations: {
                contentView.alpha = 1
                contentView.transform = .identity
                backgroundView.alpha = 1
            }) { (finished) in
                completion()
            }
        }else {
            contentView.alpha = 1
            contentView.transform = .identity
            completion()
        }
    }

    public override func dismiss(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, usingSpringWithDamping: dismissDamping, initialSpringVelocity: dismissInitialSpringVelocaity, options: dismissAnimationOptions, animations: {
                contentView.alpha = 0
                contentView.transform = self.smallTransform
                backgroundView.alpha = 0
            }) { (finished) in
                completion()
            }
        }else {
            contentView.alpha = 0
            contentView.transform = smallTransform
            completion()
        }
    }
}
