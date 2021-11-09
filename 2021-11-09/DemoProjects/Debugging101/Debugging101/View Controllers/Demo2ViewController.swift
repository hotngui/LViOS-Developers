//
// Created by Joey Jarosz on 11/9/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
class Demo2ViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!

    var x: Int = 0
    var y: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func calculateTapped(_ sender: UIButton) {
        x = 5
        y = 1

        let z = x + y

        label.text = "\(x) + \(y) = \(z)"
    }
}
