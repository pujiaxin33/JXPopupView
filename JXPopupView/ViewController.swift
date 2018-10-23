//
//  ViewController.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var contentView: TestAlertView!
    var backgroundStyle = JXPopupViewBackgroundStyle.solidColor
    var backgroundColor = UIColor.black.withAlphaComponent(0.3)
    var backgroundEffectStyle = UIBlurEffect.Style.light
    var animationIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func backgroundItemClicked(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "BackgroundViewController") as! BackgroundViewController
        vc.didSelectRowCallback = {(indexPath) in
            switch indexPath.row {
            case 0:
                self.backgroundStyle = .solidColor
                self.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            case 1:
                self.backgroundStyle = .blur
                self.backgroundEffectStyle = .light
            case 2:
                self.backgroundStyle = .blur
                self.backgroundEffectStyle = .dark
            default:
                break
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func animationItemClicked(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AnimationViewController") as! AnimationViewController
        vc.didSelectRowCallback = {(indexPath) in
            self.animationIndex = indexPath.row
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func displayButtonClicked(_ sender: UIButton) {
        //- 确定contentView的目标frame
        contentView = Bundle.main.loadNibNamed("TestAlertView", owner: nil, options: nil)?.first as? TestAlertView
        let x: CGFloat = (self.view.bounds.size.width - 200)/2
        let y: CGFloat = (self.view.bounds.size.height - 200)/2
        contentView.frame = CGRect(x: x, y: y, width: 200, height: 200)
        //- 确定动画效果
        var animator: JXPopupViewAnimationProtocol?
        switch animationIndex {
        case 0:
            animator = JXPopupViewFadeInOutAnimator()
        case 1:
            animator = JXPopupViewZoomInOutAnimator()
        case 2:
            animator = JXPopupViewUpwardAnimator()
        case 3:
            animator = JXPopupViewDownwardAnimator()
        case 4:
            animator = JXPopupViewLeftwardAnimator()
        case 5:
            animator = JXPopupViewRightwardAnimator()
        case 6:
            animator = JXPopupViewDownwardAnimator()
            let customAnimator = animator as! JXPopupViewDownwardAnimator
            customAnimator.customDisplayAnimateCallback = {[weak customAnimator] (_, _, animationBlock, completionBlock) in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: customAnimator!.displayAnimationOptions, animations: {
                    animationBlock()
                }, completion: { (finished) in
                    completionBlock(finished)
                })
            }
        case 7:
            animator = JXPopupViewDownwardAnimator()
            let customAnimator = animator as! JXPopupViewDownwardAnimator
            customAnimator.customDisplayAnimateCallback = {(contentView, backgroundView, _, completionBlock) in
                UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    contentView.frame = CGRect(x: 50, y: 200, width: 200, height: 200)
                    backgroundView.alpha = 1
                }, completion: { (finished) in
                    completionBlock(finished)
                })
            }
            customAnimator.customDismissAnimateCallback = {[weak self] (contentView, backgroundView, _, completionBlock) in
                UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    contentView.frame = CGRect(x: self!.view.bounds.size.width, y: self!.view.bounds.size.height, width: 200, height: 200)
                    backgroundView.alpha = 0
                }, completion: { (finished) in
                    completionBlock(finished)
                })
            }
        default:
            break
        }
        let popupView = JXPopupView(containerView: self.view, contentView: contentView, animator: animator!)
        //配置交互
        popupView.isDismissible = true
        popupView.isInteractive = true
        popupView.isPenetrable = false
        //- 配置背景
        popupView.backgroundView.style = self.backgroundStyle
        popupView.backgroundView.blurEffectStyle = self.backgroundEffectStyle
        popupView.backgroundView.color = self.backgroundColor
        popupView.display(animated: true, completion: nil)
    }

    @IBAction func dismissButtonClicked(_ sender: UIButton) {
        contentView.jx_popupView?.dismiss(animated: true, completion: nil)
    }
}

