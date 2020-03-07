//
//  Created by Joey Jarosz on 3/7/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
///
class DynamicViewController: UIViewController {
    @IBOutlet private weak var label1: UILabel!
    @IBOutlet private weak var label2: UILabel!
    @IBOutlet private weak var label3: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var colorView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        label1.text = NSLocalizedString("Please tap the button",
                                        comment: "Put a useful comment here.")

        label2.text = NSLocalizedString("Hello:",
                                        comment: "a prompt")

        label3.text = NSLocalizedString("Please tap the button",
                                        comment: "Make sure the translator knows this is not the same string as the one above it.")

        imageView.image = UIImage(named: "Flag")
        colorView.backgroundColor = UIColor(named: "DangerColor")

        // Date Examples
        let now = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        dateFormatter.locale = Locale(identifier: "en_US")
        print("EN: \(dateFormatter.string(from: now))")

        dateFormatter.locale = Locale(identifier: "de_DE")
        print("DE: \(dateFormatter.string(from: now))")

        dateFormatter.locale = Locale(identifier: "ar_SA")
        print("AR: \(dateFormatter.string(from: now))")

        // Currency Examples
        let value: NSNumber = 1234.56

        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency

        currencyFormatter.locale = Locale(identifier: "en_US")
        print("EN: \(String(describing: currencyFormatter.string(from: value)))")

        currencyFormatter.locale = Locale(identifier: "de_DE")
        print("DE: \(String(describing: currencyFormatter.string(from: value)))")

        currencyFormatter.locale = Locale(identifier: "ar_SA")
        print("AR: \(String(describing: currencyFormatter.string(from: value)))")
    }
}
