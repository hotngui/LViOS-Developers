//
// Created by Joey Jarosz on 3/21/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

/// This ViewController acts as a delegate for the `ColorView` instance, but there is a problem with that which
/// forces it to stay in memory...
///
class Test1ViewController: UIViewController {
    @IBOutlet private var colorView: ColorView!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorView.layer.borderColor = UIColor.black.cgColor
        colorView.layer.borderWidth = 0.5
        
        colorView.delegate = self
    }

    // MARK: - Actions / Selectors
    
    @IBAction
    private func buttonOneTapped(_ sender: UIButton){
        colorView.color = UIColor.yellow
    }
    
    @IBAction
    private func doneTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
}

///
extension Test1ViewController: ColorViewDelegate {
    func colorView(_ colorView: ColorView, set color: UIColor) {
        print("New Color: \(color)")
    }
}
