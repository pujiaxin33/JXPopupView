//
//  JXPopupViewSpringDownwardAnimator.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/23.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

class SpringDownwardAnimator: DownwardAnimator {

    public override func display(contentView: UIView, backgroundView: PopupView.BackgroundView, animated: Bool, completion: @escaping () -> ()) {
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: displayAnimationOptions, animations: {
                self.displayAnimationBlock?()
            }) { (finished) in
                completion()
            }
        }else {
            self.displayAnimationBlock?()
            completion()
        }
    }
}