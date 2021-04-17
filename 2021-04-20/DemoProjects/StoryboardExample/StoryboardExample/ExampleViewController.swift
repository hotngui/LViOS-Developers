//
// Created by Joey Jarosz on 4/17/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

class ExampleViewController: UIViewController {
    @IBOutlet private weak var displayLabel: UILabel!

    private let completion: (String) -> Void
    private let someValue: Int

    // MARK: - View Lifecycle

    /// Custom Initializer
    ///
    /// - Parameters:
    ///   - coder: The coder (i.e. storyboard object)
    ///   - someValue: Just something we'll display for demo purposes
    ///   - completion: A method to be called when we are done with this view controller so its owner can makeit go away
    ///
    init?(coder: NSCoder, someValue: Int, completion: @escaping (String) -> Void) {
        self.someValue = someValue
        self.completion = completion

        super.init(coder: coder)
    }

    /// - Important: Since this view controller requires values for its properties during initialization we have to make sure the caller does not try load it up using this
    /// initializer; so we fail fast if they do try...
    ///
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// :nodoc:
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLabel.text = "Value: \(someValue)"
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func buttonTapped(_ sender: UIButton) {
        let result = sender.title(for: .normal) ?? ""
        completion(result)
    }
}
