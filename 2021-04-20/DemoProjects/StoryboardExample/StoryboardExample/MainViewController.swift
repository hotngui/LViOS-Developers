//
// Created by Joey Jarosz on 4/17/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

class MainViewController: UITableViewController {

    // MARK: UITableViewDelegate Protocol

    /// When the user selects one of the rows of the table view we want to present the Example View Controller
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ItemSegue", sender: self)
    }

    // MARK: - Actions / Selectors / Segues

    /// This method gets called by any view controller presented/shown from this view controller. Those other view controllers point their __unwind segues__ at this method
    /// which also causes them to be taken off the screen...
    @IBAction private func myUnwindAction(unwindSegue: UIStoryboardSegue) {
        if let fromIdentifier = unwindSegue.identifier {
            print("Unwound from \"\(fromIdentifier)\" to here...")
        }
    }

    /// This method will get called by the segue that wants to display an instance of _ExampleViewController_ while directly passing it important information that is
    /// needed when its being initialized...
    @IBSegueAction private func showExampleVC(_ coder: NSCoder) -> ExampleViewController? {
        if let selectedIndex = tableView.indexPathForSelectedRow?.row {
            let vc = ExampleViewController(coder: coder, someValue: selectedIndex + 1, completion: { [weak self] (result) in
                self?.presentedViewController?.dismiss(animated: true)
                print("Result: \(result)")
            })
            return vc
        }

        return nil
    }
}

