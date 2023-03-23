//
// Created by Joey Jarosz on 3/21/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

/// A simple class that does nothing useful, but demonstrates what happens in memory when you forget `weak` definition of the optional delegate...
///
class ColorView: UIView {
    var delegate: ColorViewDelegate?
    
    var color: UIColor = UIColor.clear {
        didSet {
            backgroundColor = color
            delegate?.colorView(self, set: color)
        }
    }
}

///
protocol ColorViewDelegate: AnyObject {
    func colorView(_ colorView: ColorView, set color: UIColor)
}
