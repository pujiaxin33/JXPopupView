//
//  JXPopupViewCustomAnimator.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/23.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

//从左上角到中间，再到右下角
class CustomAnimator: BaseAnimator {

    override func setup(popupView: PopupView, contentView: UIView, backgroundView: PopupView.BackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)

        //仅支持frame、center类型layout
        if case .frame(var frame) = self.layout {
            frame.origin.x = -frame.size.width
            frame.origin.y = -frame.size.height
            contentView.frame = frame
        }else {
            popupView.centerXConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
            popupView.centerYConstraint(firstItem: contentView)?.constant = -(popupView.bounds.size.height/2 + contentView.bounds.size.height/2)
            popupView.layoutIfNeeded()
        }
        backgroundView.alpha = 0

        displayAnimationBlock = { [weak self] in
            guard let self = self else { return }
            backgroundView.alpha = 1
            if case .frame(let frame) = self.layout {
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = self.layout.offsetX()
                popupView.centerYConstraint(firstItem: contentView)?.constant = self.layout.offsetY()
                popupView.layoutIfNeeded()
            }
        }
        dismissAnimationBlock = {
            backgroundView.alpha = 0
            if case .frame(var frame) = self.layout {
                frame.origin.x = popupView.bounds.size.width
                frame.origin.y = popupView.bounds.size.height
                contentView.frame = frame
            }else {
                popupView.centerXConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.width/2 + contentView.bounds.size.width/2)
                popupView.centerYConstraint(firstItem: contentView)?.constant = (popupView.bounds.size.height/2 + contentView.bounds.size.height/2)
                popupView.layoutIfNeeded()
            }
        }
    }

}
