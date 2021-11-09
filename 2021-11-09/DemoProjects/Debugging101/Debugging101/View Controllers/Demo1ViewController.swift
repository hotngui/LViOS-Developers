//
// Created by Joey Jarosz on 11/9/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
protocol Demo1Delegate: AnyObject {
    func doSomething(_ message: String)
}

///
class Demo1ViewController: UIViewController {
    //weak var delegate: Demo1Delegate? // You need to mark this as a "weak" reference, otherwise it creates memory leak
    var delegate: Demo1Delegate?

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func buttonTapped(_ sender: UIButton) {
        delegate?.doSomething("This is a test, just a test...")
    }
}
