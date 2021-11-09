//
// Created by Joey Jarosz on 11/9/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
class MainViewController: UIViewController, OtherDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - View Lifecycle

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowOther" {
            if let navVC = segue.destination as? UINavigationController, let vc = navVC.viewControllers.first as? OtherViewController {
                vc.delegate = self
            }
        }
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func unwind( _ seg: UIStoryboardSegue) {
        dismiss(animated: true)
    }

    // MARK: - OtherDelegate Implementation

    func doSomething(_ message: String) {
        print("MESSAGE: \(message)")
    }
}

