//
//  Created by Joey Jarosz on 3/7/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

///
///
class MyTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if let item = self.tabBar.items?.last {
            item.title = NSLocalizedString("Two", comment: "The number 2")
        }
    }
}
