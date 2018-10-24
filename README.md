# JXPopupView
一个轻量级的自定义视图弹出框架，可灵活配置动画、背景风格。

# 特性

- 默认提供丰富的动画效果，而且可以灵活的扩展配置，只要遵从并实现`JXPopupViewAnimationProtocol`协议即可；
- 使用灵活，通过view封装，可以在任何view上面展示，并不局限于UIViewController；
- 背景配置方便，借鉴了`MBProgressHUD`对背景视图的处理逻辑，可以灵活配置；
- 交互细节可配置，提供了`isDismissible`、`isInteractive`、`isPenetrable`属性进行配置

# 预览

## 动画效果

动画效果 |  GIF
----------|--------------
| 渐隐渐现  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/FadeInOut.gif) |
| 缩放  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/ZoomInOut.gif) |
| 往左  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Leftward.gif) |
| 往右  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Rightward.gif) |
| 往下  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Downward.gif) |
| 往上  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Upward.gif) |
| 部分自定义-弹性动画  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Spring.gif) |
| 完全自定义动画  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/CustomAnimation.gif) |

## 背景风格

背景风格 |  GIF
----------|--------------
| 固定色值  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/FadeInOut.gif) |
| blur light  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/Blurlight.gif) |
| blur dark  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/BlurDark.gif) |

## 指定containerView

指定containerView |  GIF
----------|--------------
| Window  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/ZoomInOut.gif) |
| UIViewController.view  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/VCView.gif) |
| CustomView  | ![GIF](https://github.com/pujiaxin33/JXPopupView/blob/master/JXPopupView/GIF/CustomView.gif) |

# 要求

Swift 4.2编写，支持iOS9以上

# 安装

## CocoaPods

在Podfile文件里面添加
```
pod 'JXPopupView'
```
然后再pod install（最好先pod update）

# 使用

```
//- 确定contentView的目标frame
let contentView = Bundle.main.loadNibNamed("TestAlertView", owner: nil, options: nil)?.first as? TestAlertView
let x: CGFloat = (containerView.bounds.size.width - 200)/2
let y: CGFloat = (containerView.bounds.size.height - 200)/2
contentView.frame = CGRect(x: x, y: y, width: 200, height: 200)
//- 确定动画效果
var animator = JXPopupViewFadeInOutAnimator()
//- 初始化JXPopupView
let popupView = JXPopupView(containerView: containerView, contentView: contentView, animator: animator!)
//- 配置交互
popupView.isDismissible = true
popupView.isInteractive = true
popupView.isPenetrable = false
//- 配置背景
popupView.backgroundView.style = self.backgroundStyle
popupView.backgroundView.blurEffectStyle = self.backgroundEffectStyle
popupView.backgroundView.color = self.backgroundColor
//- 展示popupView
popupView.display(animated: true, completion: nil)
//- 消失popupView
//通过extension提供的jx_popupView属性，获取JXPopupView进行操作，可以不用全局持有JXPopupView属性
contentView.jx_popupView?.dismiss(animated: true, completion: nil)
```

# 动画自定义

## `JXPopupViewAnimationProtocol`协议方法

```
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
```

## 自定义动画建议

- 现有动画微调
继承对应的animator，重载协议方法，进行微调。参考demo工程的`JXPopupViewSpringDownwardAnimator`类。

- 完全自定义动画
可以继承`JXPopupViewBaseAnimator`或者自己新建一个类，遵从`JXPopupViewAnimationProtocol`协议，实现对应方法即可。参考demo工程的`JXPopupViewCustomAnimator`类

# 证书

JXPopupView is available under the MIT license. See the LICENSE file for more info.
