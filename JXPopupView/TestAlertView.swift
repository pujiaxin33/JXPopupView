//
//  TestAlertView.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/22.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

class TestAlertView: UIView {

    @IBAction func buttonClicked(_ sender: UIButton) {
        sender.setTitle("修改成功", for: UIControl.State.normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        
    }
}
