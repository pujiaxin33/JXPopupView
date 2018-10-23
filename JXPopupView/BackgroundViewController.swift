//
//  BackgroundViewController.swift
//  JXPopupView
//
//  Created by jiaxin on 2018/10/23.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

class BackgroundViewController: UITableViewController {
    var didSelectRowCallback: ((IndexPath)->())?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRowCallback?(indexPath)
        self.navigationController?.popViewController(animated: true)
    }

}
