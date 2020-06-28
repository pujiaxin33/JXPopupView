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
    var backgroundStyle: PopupView.BackgroundView.BackgroundStyle = .solidColor
    var backgroundColor = UIColor.black.withAlphaComponent(0.3)
    var backgroundEffectStyle = UIBlurEffect.Style.light
    var animationIndex: Int = 0
    var layoutIndex: Int = 0
    var containerView: UIView!
    @IBOutlet weak var customView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func backgroundItemClicked(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "BackgroundViewController") as! BackgroundViewController
        vc.didSelectRowCallback = {[weak self] (indexPath) in
            guard let self = self else {
                return
            }
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
        vc.didSelectRowCallback = {[weak self] (indexPath) in
            self?.animationIndex = indexPath.row
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let layoutVC = segue.destination as? LayoutPickerViewController {
            layoutVC.didSelectRowCallback = {[weak self] (indexPath) in
                self?.layoutIndex = indexPath.row
            }
        }
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
        contentView = Bundle.main.loadNibNamed("TestAlertView", owner: nil, options: nil)?.first as? TestAlertView
        //- 确定动画效果及其布局
        var layout: BaseAnimator.Layout?
        switch layoutIndex {
        case 0:
            layout = .center(.init())
        case 1:
            layout = .top(.init(topMargin: 100))
        case 2:
            layout = .bottom(.init(bottomMargin: 34))
        case 3:
            layout = .leading(.init(leadingMargin: 20))
        case 4:
            layout = .trailing(.init(trailingMargin: 20))
        case 5:
            layout = .frame(CGRect(x: 100, y: 300, width: 200, height: 200))
        default: break
        }
        var animator: PopupViewAnimator?
        switch animationIndex {
        case 0:
            animator = FadeInOutAnimator(layout: layout!)
        case 1:
            animator = ZoomInOutAnimator(layout: layout!)
        case 2:
            animator = UpwardAnimator(layout: layout!)
        case 3:
            animator = DownwardAnimator(layout: layout!)
        case 4:
            animator = LeftwardAnimator(layout: layout!)
        case 5:
            animator = RightwardAnimator(layout: layout!)
        case 6:
            let spring = DownwardAnimator(layout: layout!)
            spring.displayDuration = 0.5
            spring.displaySpringDampingRatio = 0.7
            spring.displaySpringVelocity = 0.5
            animator = spring
        case 7:
            animator = CustomAnimator(layout: layout!)
        default:
            break
        }
        let popupView = PopupView(containerView: containerView, contentView: contentView, animator: animator!)
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
        contentView.popupView()?.dismiss(animated: true, completion: nil)
    }
}

