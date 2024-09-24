//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SwiftTestingSample

@Suite("Parameterized Tests")
struct Parameterized {
    @Test(arguments: [5, 3, 2], [4, 2, 1])
    func addValues(x: Int, y: Int) {
        let model = Model()
        
        let _ = model.add(x)
        let _ = model.add(y)
        
        #expect(model.result == (x + y))
    }
    
    @Test(arguments: [5, 3, 2, 1])
    func addTwoValues(x: Int) {
        let model = Model()
        
        let _ = model.add(x)
        let _ = model.add(x)
        
        #expect(model.result == (x * 2))
    }
}
