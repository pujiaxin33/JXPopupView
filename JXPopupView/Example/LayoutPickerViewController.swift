//
//  LayoutPickerViewController.swift
//  JXPopupView
//
//  Created by jiaxin on 2020/6/27.
//  Copyright © 2020 jiaxin. All rights reserved.
//

import UIKit

class LayoutPickerViewController: UITableViewController {
    var didSelectRowCallback: ((IndexPath)->())?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowCallback?(indexPath)
        self.navigationController?.popViewController(animated: true)
    }

}
