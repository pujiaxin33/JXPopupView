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

    let containerView: UIView
    let contentView: UIView
    let animator: JXPopupViewAnimationProtocol
    var isAnimating = false

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
    public var displayDuration: TimeInterval = 0.25
    public var displayAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    var displayAnimateBlock: (()->())?

    public var dismissDuration: TimeInterval = 0.25
    public var dismissAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    var dismissAnimateBlock: (()->())?

    public func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
    }

    public func display(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
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

    public func dismiss(contentView: UIView, backgroundView: JXBackgroundView, animated: Bool, completion: @escaping () -> ()) {
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

public class JXPopupViewLeftwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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

public class JXPopupViewRightwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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

public class JXPopupViewUpwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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

public class JXPopupViewDownwardAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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

public class JXPopupViewFadeInOutAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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

public class JXPopupViewZoomInOutAnimator: JXPopupViewBaseAnimator {
    public override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
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
