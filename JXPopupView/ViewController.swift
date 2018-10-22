//
//  ViewController.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let contentView = TestAlertView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let button = UIButton(type: .custom)
        button.frame = self.view.bounds
        view.addSubview(button)
        button.addTarget(self, action: #selector(buttonClicked), for: UIControl.Event.touchUpInside)
    }

    @objc func buttonClicked() {
        contentView.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        contentView.center = self.view.center
        let animator = JXPopupViewZoomInOutAnimator()
        //        animator.displayDamping = 0.5
        //        animator.displayInitialSpringVelocaity = 0.1
        let popupView = JXPopupView(containerView: self.view, contentView: contentView, animator: animator)
        popupView.penetrable = true
//        popupView.dismissable = true
        popupView.backgroundView.style = .blur
        popupView.backgroundView.blurEffectStyle = .light
        popupView.backgroundView.color = UIColor.clear
        popupView.display(animated: true, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        contentView.jx_popupView?.dismiss(animated: true, completion: nil)
    }

    


}

