//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

/// A simple tableView cell that contains two labels used to display the name and address of the restaurant. See the Storyboard for how its laid out.
///
class RestaurantCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    func configure(name: String, address: String) {
        self.nameLabel.text = name
        self.addressLabel.text = address
    }
}
