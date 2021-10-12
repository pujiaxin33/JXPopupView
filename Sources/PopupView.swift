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
    ///   - popupView: PopupView
    ///   - contentView: 自定义的弹框视图
    ///   - backgroundView: 背景视图
    /// - Returns: void
    func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView)


    /// 横竖屏切换的时候，刷新布局
    /// - Parameters:
    ///   - popupView: PopupView
    ///   - contentView: 自定义的弹框视图
    func refreshLayout(popupView: PopupView, contentView: UIView)

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
/// 通过面对协议PopupViewAnimator，实现对动画的灵活配置
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
    public private(set) var isPresenting = false
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
    ///   - animator: 遵从协议PopupViewAnimator的动画驱动器
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

        animator.setup(popupView: self, contentView: contentView, backgroundView: backgroundView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = bounds
        animator.refreshLayout(popupView: self, contentView: contentView)
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
        isPresenting = true
        isAnimating = true
        containerView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

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
            self.isPresenting = false
            self.contentView.removeFromSuperview()
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
    open var displayAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    //displaySpringDampingRatio、displaySpringVelocity属性同时有值，才会使用spring动画方法。dismissSpringDampingRatio、dismissSpringVelocity同理。
    open var displaySpringDampingRatio: CGFloat?
    open var displaySpringVelocity: CGFloat?
    /// 展示动画的配置block
    open var displayAnimationBlock: (()->())?

    open var dismissDuration: TimeInterval = 0.25
    open var dismissAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    open var dismissSpringDampingRatio: CGFloat?
    open var dismissSpringVelocity: CGFloat?
    /// 消失动画的配置block
    open var dismissAnimationBlock: (()->())?

    public enum Layout {
        case center(Center)
        case top(Top)
        case bottom(Bottom)
        case leading(Leading)
        case trailing(Trailing)
        case frame(CGRect)

        func offsetX() -> CGFloat {
            switch self {
            case .center(let center):
                return center.offsetX
            case .top(let top):
                return top.offsetX
            case .bottom(let bottom):
                return bottom.offsetX
            case .leading(_), .trailing(_), .frame(_):
                return 0
            }
        }

        func offsetY() -> CGFloat {
            switch self {
            case .center(let center):
                return center.offsetY
            case .leading(let leading):
                return leading.offsetY
            case .trailing(let trailing):
                return trailing.offsetY
            case .top(_), .bottom(_), .frame(_):
                return 0
            }
        }

        public struct Center {
            public var offsetY: CGFloat
            public var offsetX: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            /// 如果contentView重载了intrinsicContentSize属性并返回其内容的CGSize，就无需再设置width、height值。
            /// - Parameters:
            ///   - offsetY: Y轴上的偏移值
            ///   - offsetX: X轴上的偏移值
            ///   - width: 宽度值，赋值之后会添加width约束
            ///   - height: 高度值，赋值之后会添加height约束
            public init(offsetY: CGFloat = 0, offsetX: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.offsetY = offsetY
                self.offsetX = offsetX
                self.width = width
                self.height = height
            }
        }

        public struct Top {
            public var topMargin: CGFloat
            public var offsetX: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            /// 如果contentView重载了intrinsicContentSize属性并返回其内容的CGSize，就无需再设置width、height值。
            /// - Parameters:
            ///   - topMargin: 顶部边距
            ///   - offsetX: X轴上的偏移值
            ///   - width: 宽度值，赋值之后会添加width约束
            ///   - height: 高度值，赋值之后会添加height约束
            public init(topMargin: CGFloat = 0, offsetX: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.topMargin = topMargin
                self.offsetX = offsetX
                self.width = width
                self.height = height
            }
        }

        public struct Bottom {
            public var bottomMargin: CGFloat
            public var offsetX: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            /// 如果contentView重载了intrinsicContentSize属性并返回其内容的CGSize，就无需再设置width、height值。
            /// - Parameters:
            ///   - bottomMargin: 底部边距
            ///   - offsetX: X轴上的偏移值
            ///   - width: 宽度值，赋值之后会添加width约束
            ///   - height: 高度值，赋值之后会添加height约束
            public init(bottomMargin: CGFloat = 0, offsetX: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.bottomMargin = bottomMargin
                self.offsetX = offsetX
                self.width = width
                self.height = height
            }
        }

        public struct Leading {
            public var leadingMargin: CGFloat
            public var offsetY: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            /// 如果contentView重载了intrinsicContentSize属性并返回其内容的CGSize，就无需再设置width、height值。
            /// - Parameters:
            ///   - leadingMargin: leading边距
            ///   - offsetY: Y轴上的偏移值
            ///   - width: 宽度值，赋值之后会添加width约束
            ///   - height: 高度值，赋值之后会添加height约束
            public init(leadingMargin: CGFloat = 0, offsetY: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.leadingMargin = leadingMargin
                self.offsetY = offsetY
                self.width = width
                self.height = height
            }
        }

        public struct Trailing {
            public var trailingMargin: CGFloat
            public var offsetY: CGFloat
            public var width: CGFloat?
            public var height: CGFloat?

            /// 如果contentView重载了intrinsicContentSize属性并返回其内容的CGSize，就无需再设置width、height值。
            /// - Parameters:
            ///   - trailingMargin: trailing边距
            ///   - offsetY: Y轴上的偏移值
            ///   - width: 宽度值，赋值之后会添加width约束
            ///   - height: 高度值，赋值之后会添加height约束
            public init(trailingMargin: CGFloat = 0, offsetY: CGFloat = 0, width: CGFloat? = nil, height: CGFloat? = nil) {
                self.trailingMargin = trailingMargin
                self.offsetY = offsetY
                self.width = width
                self.height = height
            }
        }
    }

    public init(layout: Layout = .center(.init())) {
        self.layout = layout
    }

    open func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        switch layout {
        case .center(let center):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: center.offsetX).isActive = true
            contentView.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: center.offsetY).isActive = true
            if let width = center.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = center.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .top(let top):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: top.topMargin).isActive = true
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: top.offsetX).isActive = true
            if let width = top.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = top.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .bottom(let bottom):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -bottom.bottomMargin).isActive = true
            contentView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor, constant: bottom.offsetX).isActive = true
            if let width = bottom.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = bottom.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .leading(let leading):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: leading.leadingMargin).isActive = true
            contentView.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: leading.offsetY).isActive = true
            if let width = leading.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = leading.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .trailing(let trailing):
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -trailing.trailingMargin).isActive = true
            contentView.centerYAnchor.constraint(equalTo: popupView.centerYAnchor, constant: trailing.offsetY).isActive = true
            if let width = trailing.width {
                contentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            }
            if let height = trailing.height {
                contentView.heightAnchor.constraint(equalToConstant: height).isActive = true
            }
        case .frame(let frame):
            contentView.frame = frame
        }
    }

    open func refreshLayout(popupView: PopupView, contentView: UIView) {
        if case .frame(let frame) = layout {
            contentView.frame = frame
        }
    }

    open func display(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            if let displaySpringDampingRatio = displaySpringDampingRatio, let displaySpringVelocity = displaySpringVelocity {
                UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displaySpringDampingRatio, initialSpringVelocity: displaySpringVelocity, options: displayAnimationOptions, animations: {
                    self.displayAnimationBlock?()
                }) { (_) in
                    completion()
                }
            }else {
                UIView.animate(withDuration: displayDuration, delay: 0, options: displayAnimationOptions, animations: {
                    self.displayAnimationBlock?()
                }) { (_) in
                    completion()
                }
            }
        }else {
            self.displayAnimationBlock?()
            completion()
        }
    }

    open func dismiss(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            if let displaySpringDampingRatio = displaySpringDampingRatio, let displaySpringVelocity = displaySpringVelocity {
                UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displaySpringDampingRatio, initialSpringVelocity: displaySpringVelocity, options: displayAnimationOptions, animations: {
                    self.dismissAnimationBlock?()
                }) { (_) in
                    completion()
                }
            }else {
                UIView.animate(withDuration: dismissDuration, delay: 0, options: dismissAnimationOptions, animations: {
                    self.dismissAnimationBlock?()
                }) { (finished) in
                    completion()
                }
            }

        }else {
            self.dismissAnimationBlock?()
            completion()
        }
    }
}

open class LeftwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

        let fromClosure = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 0
            switch self.layout {
            case .frame(var frame):
                frame.origin.x = popupView.bounds.size.width
                contentView.frame = frame
            case .center(_), .top(_), .bottom(_):
                popupView.centerXConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
                popupView.layoutIfNeeded()
            case .leading(_):
                popupView.leadingConstraint(firstItem: contentView)?.constant = popupView.bounds.size.width
                popupView.layoutIfNeeded()
            case .trailing(_):
                popupView.trailingConstraint(firstItem: contentView)?.constant = popupView.bounds.size.width
                popupView.layoutIfNeeded()
            }
        }
        fromClosure()

        displayAnimationBlock = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 1
            switch self.layout {
            case .frame(let frame):
                contentView.frame = frame
            case .center(_), .top(_), .bottom(_):
                popupView.centerXConstraint(firstItem: contentView)?.constant = self.layout.offsetX()
                popupView.layoutIfNeeded()
            case .leading(let leading):
                popupView.leadingConstraint(firstItem: contentView)?.constant = leading.leadingMargin
                popupView.layoutIfNeeded()
            case .trailing(let trailing):
                popupView.trailingConstraint(firstItem: contentView)?.constant = -trailing.trailingMargin
                popupView.layoutIfNeeded()
            }
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class RightwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

        let fromClosure = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 0
            switch self.layout {
            case .frame(var frame):
                frame.origin.x = -frame.size.width
                contentView.frame = frame
            case .center(_), .top(_), .bottom(_):
                popupView.centerXConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
                popupView.layoutIfNeeded()
            case .leading(_):
                var contentViewWidth = contentView.widthConstraint(firstItem: contentView)?.constant
                if contentViewWidth == nil {
                    contentViewWidth = contentView.intrinsicContentSize.width
                }
                popupView.leadingConstraint(firstItem: contentView)?.constant = -contentViewWidth!
                popupView.layoutIfNeeded()
            case .trailing(_):
                popupView.trailingConstraint(firstItem: contentView)?.constant = -popupView.bounds.size.width
                popupView.layoutIfNeeded()
            }
        }
        fromClosure()

        displayAnimationBlock = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 1
            switch self.layout {
            case .frame(let frame):
                contentView.frame = frame
            case .center(_), .top(_), .bottom(_):
                popupView.centerXConstraint(firstItem: contentView)?.constant = self.layout.offsetX()
                popupView.layoutIfNeeded()
            case .leading(let leading):
                popupView.leadingConstraint(firstItem: contentView)?.constant = leading.leadingMargin
                popupView.layoutIfNeeded()
            case .trailing(let trailing):
                popupView.trailingConstraint(firstItem: contentView)?.constant = -trailing.trailingMargin
                popupView.layoutIfNeeded()
            }
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class UpwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

        let fromClosure = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 0
            switch self.layout {
            case .frame(var frame):
                frame.origin.y = popupView.frame.size.height
                contentView.frame = frame
            case .center(_), .leading(_), .trailing(_):
                var contentViewHeight = contentView.heightConstraint(firstItem: contentView)?.constant
                if contentViewHeight == nil {
                    contentViewHeight = contentView.intrinsicContentSize.height
                }
                popupView.centerYConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.height/2 + contentViewHeight!/2)
                popupView.layoutIfNeeded()
            case .top(_):
                popupView.topConstraint(firstItem: contentView)?.constant = popupView.bounds.size.height
                popupView.layoutIfNeeded()
            case .bottom(_):
                var contentViewHeight = contentView.heightConstraint(firstItem: contentView)?.constant
                if contentViewHeight == nil {
                    contentViewHeight = contentView.intrinsicContentSize.height
                }
                popupView.bottomConstraint(firstItem: contentView)?.constant = contentViewHeight!
                popupView.layoutIfNeeded()
            }
        }
        fromClosure()

        displayAnimationBlock = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 1
            switch self.layout {
            case .frame(let frame):
                contentView.frame = frame
            case .center(_), .leading(_), .trailing(_):
                popupView.centerYConstraint(firstItem: contentView)?.constant = self.layout.offsetY()
                popupView.layoutIfNeeded()
            case .top(let top):
                popupView.topConstraint(firstItem: contentView)?.constant = top.topMargin
                popupView.layoutIfNeeded()
            case .bottom(let bottom):
                popupView.bottomConstraint(firstItem: contentView)?.constant = -bottom.bottomMargin
                popupView.layoutIfNeeded()
            }
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class DownwardAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

        let fromClosure = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 0
            switch self.layout {
            case .frame(var frame):
                frame.origin.y = -frame.size.height
                contentView.frame = frame
            case .center(_), .leading(_), .trailing(_):
                var contentViewHeight = contentView.heightConstraint(firstItem: contentView)?.constant
                if contentViewHeight == nil {
                    contentViewHeight = contentView.intrinsicContentSize.height
                }
                popupView.centerYConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.height/2 + contentViewHeight!/2)
                popupView.layoutIfNeeded()
            case .top(_):
                var contentViewHeight = contentView.heightConstraint(firstItem: contentView)?.constant
                if contentViewHeight == nil {
                    contentViewHeight = contentView.intrinsicContentSize.height
                }
                popupView.topConstraint(firstItem: contentView)?.constant = -contentViewHeight!
                popupView.layoutIfNeeded()
            case .bottom(_):
                popupView.bottomConstraint(firstItem: contentView)?.constant = -popupView.bounds.size.height
                popupView.layoutIfNeeded()
            }
        }
        fromClosure()

        displayAnimationBlock = { [weak self, weak popupView] in
            guard let self = self, let popupView = popupView else { return }
            backgroundView.alpha = 1
            switch self.layout {
            case .frame(let frame):
                contentView.frame = frame
            case .center(_), .leading(_), .trailing(_):
                popupView.centerYConstraint(firstItem: contentView)?.constant = self.layout.offsetY()
                popupView.layoutIfNeeded()
            case .top(let top):
                popupView.topConstraint(firstItem: contentView)?.constant = top.topMargin
                popupView.layoutIfNeeded()
            case .bottom(let bottom):
                popupView.bottomConstraint(firstItem: contentView)?.constant = -bottom.bottomMargin
                popupView.layoutIfNeeded()
            }
        }
        dismissAnimationBlock = {
            fromClosure()
        }
    }
}

open class FadeInOutAnimator: BaseAnimator {
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

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
    open override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

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

    func topConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .top && $0.firstItem as? UIView == firstItem }
    }

    func bottomConstraint(firstItem: UIView) -> NSLayoutConstraint? {
       return constraints.first { $0.firstAttribute == .bottom && $0.firstItem as? UIView == firstItem }
    }

    func leadingConstraint(firstItem: UIView) -> NSLayoutConstraint? {
        return constraints.first { $0.firstAttribute == .leading && $0.firstItem as? UIView == firstItem }
    }

    func trailingConstraint(firstItem: UIView) -> NSLayoutConstraint? {
       return constraints.first { $0.firstAttribute == .trailing && $0.firstItem as? UIView == firstItem }
    }
}
