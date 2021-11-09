//
// Created by Joey Jarosz on 11/9/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
protocol OtherDelegate: AnyObject {
    func doSomething(_ message: String)
}

///
class OtherViewController: UIViewController, Demo1Delegate {
    weak var delegate: OtherDelegate?

    // MARK: - View Lifecycle

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Demo1" {
            if let destinationVC = segue.destination as? Demo1ViewController {
                destinationVC.delegate = self
            }
        }
    }

    // MARK: - Demo1Delegate Implementation

    func doSomething(_ message: String) {
        delegate?.doSomething(message)
    }
}
