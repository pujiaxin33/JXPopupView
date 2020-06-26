//
//  JXPopupView.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

public protocol PopupViewAnimator {
    /// 初始化配置动画驱动器
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - containerView: 展示弹框的视图
    /// - Returns: void
    func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView)

    /// 处理展示动画
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - animated: 是否需要动画
    ///   - completion: 动画完成后的回调
    /// - Returns: void
    func display(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping ()->())

    /// 处理消失动画
    ///
    /// - Parameters:
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    ///   - animated: 是否需要动画
    ///   - completion: 动画完成后的回调
    func dismiss(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping ()->())
}

/// 一个轻量级的自定义视图弹框框架，主要提供动画、背景的灵活配置，功能简单却强大
/// 通过面对协议JXPopupViewAnimationProtocol，实现对动画的灵活配置
/// 通过JXBackgroundView对背景进行自定义配置
public class PopupView: UIView {
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
    public let backgroundView: BackgroundView
    public var willDispalyCallback: (()->())?
    public var didDispalyCallback: (()->())?
    public var willDismissCallback: (()->())?
    public var didDismissCallback: (()->())?

    unowned let containerView: UIView
    let contentView: UIView
    let animator: PopupViewAnimator
    var isAnimating = false

    /// 指定的s初始化器
    ///
    /// - Parameters:
    ///   - containerView: 展示弹框的视图，可以是window、vc.view、自定义视图等
    ///   - contentView: 自定义的弹框视图
    ///   - animator: 遵从协议JXPopupViewAnimationProtocol的动画驱动器
    public init(containerView: UIView, contentView: UIView, animator: PopupViewAnimator = FadeInOutAnimator()) {
        self.containerView = containerView
        self.contentView = contentView
        self.animator = animator
        backgroundView = BackgroundView(frame: containerView.bounds)
        
        super.init(frame: containerView.bounds)

        backgroundView.isUserInteractionEnabled = isDismissible
        backgroundView.addTarget(self, action: #selector(backgroundViewClicked), for: .touchUpInside)
        addSubview(backgroundView)
        addSubview(contentView)

        animator.setup(popupView: self, contentView: contentView, backgroundView: backgroundView, containerView: containerView)
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

extension PopupView {

    public class BackgroundView: UIControl {

        public enum BackgroundStyle {
            case solidColor
            case blur
        }

        public var style = BackgroundStyle.solidColor {
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

        func refreshBackgroundStyle() {
            if style == .solidColor {
                effectView?.removeFromSuperview()
                effectView = nil
            }else {
                effectView = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffectStyle))
                effectView?.frame = bounds
                addSubview(effectView!)
            }
        }
    }
}

public extension UIView {
    func popupView() -> PopupView? {
        if self.superview?.isKind(of: PopupView.self) == true {
            return self.superview as? PopupView
        }
        return nil
    }
}

open class BaseAnimator: PopupViewAnimator {
    open var layout: Layout

    open var displayDuration: TimeInterval = 0.25
    open var displayAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    /// 展示动画的配置block
    open var displayAnimationBlock: (()->())?

    open var dismissDuration: TimeInterval = 0.25
    open var dismissAnimationOptions = UIView.AnimationOptions.init(rawValue: UIView.AnimationOptions.beginFromCurrentState.rawValue & UIView.AnimationOptions.curveEaseInOut.rawValue)
    /// 消失动画的配置block
    open var dismissAnimationBlock: (()->())?

    public enum Layout {
        case center(Center)
        case top(Top)
        case bottom(Bottom)
        case frame(CGRect)

        func horizontalOffset() -> CGFloat {
            switch self {
            case .center(let center):
                return center.horizontalOffset
            case .top(let top):
                return top.horizontalOffset
            case .bottom(let bottom):
                return bottom.horizontalOffset
            case .frame(_):
                return 0
            }
        }

        func verticalOffset() -> CGFloat {
            switch self {
            case .center(let center):
                return center.verticalOffset
            case .top(let top):
                return top.topMargin
            case .bottom(let bottom):
                return bottom.bottomMargin
            case .frame(_):
                return 0
            }
        }

        public struct Center {
            public var verticalOffset: CGFloat
            public var horizontalOffset: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?
            public static let zero = Center()

            public init(verticalOffset: CGFloat = 0, horizontalOffset: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.verticalOffset = verticalOffset
                self.horizontalOffset = horizontalOffset
                self.width = width
                self.height = height
            }
        }

        public struct Top {
            public var topMargin: CGFloat
            public var horizontalOffset: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?
            public static let zero = Top()

            public init(topMargin: CGFloat = 10, horizontalOffset: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.topMargin = topMargin
                self.horizontalOffset = horizontalOffset
                self.width = width
                self.height = height
            }
        }

        public struct Bottom {
            public var bottomMargin: CGFloat
            public var horizontalOffset: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            public init(bottomMargin: CGFloat = 10, horizontalOffset: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.bottomMargin = bottomMargin
                self.horizontalOffset = horizontalOffset
                self.width = width
                self.height = height
            }
        }
    }

    public init(layout: Layout = .center(.zero)) {
        self.layout = layout
    }

    open func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        switch layout {
        case .center(let center):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: center.horizontalOffset).isActive = true
            contentView.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: center.verticalOffset).isActive = true
            if let width = center.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = center.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .top(let top):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: top.topMargin).isActive = true
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: top.horizontalOffset).isActive = true
            if let width = top.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = top.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .bottom(let bottom):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: bottom.bottomMargin).isActive = true
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: bottom.horizontalOffset).isActive = true
            if let width = bottom.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = bottom.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .frame(let frame):
            contentView.frame = frame
        }
//        popupView.setNeedsLayout()
//        popupView.layoutIfNeeded()
    }

    open func display(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: displayDuration, delay: 0, options: displayAnimationOptions, animations: {
                self.displayAnimationBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.displayAnimationBlock?()
            completion()
        }
    }

    open func dismiss(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: dismissDuration, delay: 0, options: dismissAnimationOptions, animations: {
                self.dismissAnimationBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.dismissAnimationBlock?()
            completion()
        }
    }
}

open class LeftwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        let fromClosure = { [weak self] in
            guard let self = self else { return }
            if case .frame(var frame) = self.layout {
                frame.origin.x = -frame.size.width
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
            }
            popupView.layoutIfNeeded()
            backgroundView.alpha = 0
        }
        fromClosure()

        displayAnimationBlock = { [weak self] in
            guard let self = self else { return }
            backgroundView.alpha = 1
            if case .frame(let frame) = self.layout {
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = self.layout.horizontalOffset()
            }
            popupView.layoutIfNeeded()
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class RightwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        let fromClosure = { [weak self] in
            guard let self = self else { return }
            if case .frame(var frame) = self.layout {
                frame.origin.x = popupView.bounds.size.width
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
            }
            popupView.layoutIfNeeded()
            backgroundView.alpha = 0
        }
        fromClosure()

        displayAnimationBlock = { [weak self] in
            guard let self = self else { return }
            backgroundView.alpha = 1
            if case .frame(let frame) = self.layout {
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = self.layout.horizontalOffset()
            }
            popupView.layoutIfNeeded()
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class UpwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        let fromClosure = { [weak self] in
            guard let self = self else { return }
            if case .frame(var frame) = self.layout {
                frame.origin.y = popupView.frame.size.height
                contentView.frame = frame
            }else {
                popupView.centerYConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.height/2 + contentView.bounds.size.height/2)
            }
            popupView.layoutIfNeeded()
            backgroundView.alpha = 0
        }
        fromClosure()

        displayAnimationBlock = { [weak self] in
            guard let self = self else { return }
            backgroundView.alpha = 1
            if case .frame(let frame) = self.layout {
                contentView.frame = frame
            }else {
                popupView.centerYConstraint(firstItem: contentView)?.constant = self.layout.verticalOffset()
            }
            popupView.layoutIfNeeded()
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class DownwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        let fromClosure = { [weak self] in
            guard let self = self else { return }
            if case .frame(var frame) = self.layout {
                frame.origin.y = popupView.frame.size.height
                contentView.frame = frame
            }else {
                popupView.centerYConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.height/2 + contentView.bounds.size.height/2)
            }
            popupView.layoutIfNeeded()
            backgroundView.alpha = 0
        }
        fromClosure()

        displayAnimationBlock = { [weak self] in
            guard let self = self else { return }
            backgroundView.alpha = 1
            if case .frame(let frame) = self.layout {
                contentView.frame = frame
            }else {
                popupView.centerYConstraint(firstItem: contentView)?.constant = self.layout.verticalOffset()
            }
            popupView.layoutIfNeeded()
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class FadeInOutAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        contentView.alpha = 0
        backgroundView.alpha = 0

        displayAnimationBlock = {
            contentView.alpha = 1
            backgroundView.alpha = 1
        }
        dismissAnimationBlock = {
            contentView.alpha = 0
            backgroundView.alpha = 0
        }
    }
}

open class ZoomInOutAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView, containerView: UIView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView, containerView: containerView)

        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        displayAnimationBlock = {
            contentView.alpha = 1
            contentView.transform = .identity
            backgroundView.alpha = 1
        }
        dismissAnimationBlock = {
            contentView.alpha = 0
            contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            backgroundView.alpha = 0
        }
    }
}


extension UIView {
    func widthConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .width && $0.firstItem as? UIView == firstItem }
    }

    func heightConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .height && $0.firstItem as? UIView == firstItem }
    }

    func centerXConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .centerX && $0.firstItem as? UIView == firstItem }
    }

    func centerYConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .centerY && $0.firstItem as? UIView == firstItem }
    }
}
