//
// Created by Joey Jarosz on 3/7/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

class LocationViewController: UITableViewController {
    private var handler: ((String?) -> Void)

    init?(coder: NSCoder, handler: @escaping (String?) -> Void) {
        self.handler = handler
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            handler(cell.textLabel?.text)
        }
    }

    @IBAction
    private func cancelTapped(_ sender: Any) {
        handler(nil)
    }
}
