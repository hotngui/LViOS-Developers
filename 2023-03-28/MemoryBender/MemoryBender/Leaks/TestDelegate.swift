//
// Created by Joey Jarosz on 3/21/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

protocol TestDelegate: AnyObject {
    func didActionOne()
    func didActionTwo()
}

extension TestDelegate {
    func didActionOne() {
        //NOP
    }
    
    func didActionTwo() {
        //NOP
    }
}
