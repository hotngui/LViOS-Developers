//
// Created by Joey Jarosz on 3/21/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import UIKit

/// Our springboard to our various tests...
///
class ViewController: UIViewController {
    /// This method creates a few objects that point at each other. Since they are local objects they
    /// should be freed automatically when the method returns...
    ///
    @IBAction private func simpleLeakTapped(_ sender: Any) {
        let a = DataObject("Hello")
        let b = DataObject("World")
        let c = DataObject("Again")
        
        a.next = b
        
        b.previous = a
        b.next = c
        
        c.next = a
        c.previous = b
    }
}

///  A simple data object that has references to other data objects - think doubly-linked lists...
///
class DataObject {
    var next: DataObject?
    var previous: DataObject?
    
    var text: String
    
    init(_ text: String) {
        self.text = text
    }
}
