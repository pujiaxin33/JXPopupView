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
    var containerView: UIView!
    @IBOutlet weak var customView: UIView!

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

    @IBAction func customViewDisplayButtonClicked(_ sender: UIButton) {
        containerView = customView
        displayPopupView()
    }

    @IBAction func vcviewDisplayButtonClicked(_ sender: UIButton) {
        containerView = self.view
        displayPopupView()
    }

    @IBAction func windowDisplayButtonClicked(_ sender: UIButton) {
        containerView = UIApplication.shared.keyWindow!
        displayPopupView()
    }

    func displayPopupView() {
        //- 确定contentView的目标frame
        contentView = Bundle.main.loadNibNamed("TestAlertView", owner: nil, options: nil)?.first as? TestAlertView
        let x: CGFloat = (containerView.bounds.size.width - 200)/2
        let y: CGFloat = (containerView.bounds.size.height - 200)/2
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
            animator = JXPopupViewSpringDownwardAnimator()
        case 7:
            animator = JXPopupViewCustomAnimator()
        default:
            break
        }
        let popupView = JXPopupView(containerView: containerView, contentView: contentView, animator: animator!)
        //配置交互
        popupView.isDismissible = true
        popupView.isInteractive = true
        //可以设置为false，再点击弹框中的button试试？
//        popupView.isInteractive = false
        popupView.isPenetrable = false
        //- 配置背景
        popupView.backgroundView.style = self.backgroundStyle
        popupView.backgroundView.blurEffectStyle = self.backgroundEffectStyle
        popupView.backgroundView.color = self.backgroundColor
        popupView.display(animated: true, completion: nil)
    }

    @IBAction func dismissButtonClicked(_ sender: UIBarButtonItem) {
        guard contentView != nil else {
            return;
        }
        //通过extension提供的jx_popupView属性，获取JXPopupView进行操作，可以不用全局持有JXPopupView属性
        contentView.jx_popupView?.dismiss(animated: true, completion: nil)
    }
}

