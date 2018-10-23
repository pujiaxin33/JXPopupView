//
//  JXPopupViewCustomAnimator.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/23.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

//从左上角到中间，再到右下角
class JXPopupViewCustomAnimator: JXPopupViewBaseAnimator {

    override func setup(contentView: UIView, backgroundView: JXBackgroundView, containerView: UIView) {
        var frame = contentView.frame
        frame.origin.x = -contentView.bounds.size.width
        frame.origin.y = -contentView.bounds.size.height
        let sourceRect = frame

        let targetRect = contentView.frame

        var dismissRect = contentView.frame
        dismissRect.origin.x = containerView.bounds.size.width
        dismissRect.origin.y = containerView.bounds.size.height

        contentView.frame = sourceRect
        backgroundView.alpha = 0

        displayAnimateBlock = {
            contentView.frame = targetRect
            backgroundView.alpha = 1
        }
        dismissAnimateBlock = {
            contentView.frame = dismissRect
            backgroundView.alpha = 0
        }
    }

}
