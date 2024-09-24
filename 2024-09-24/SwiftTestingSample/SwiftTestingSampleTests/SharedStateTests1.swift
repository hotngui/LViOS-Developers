//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SwiftTestingSample

@Suite("Shared State Tests 1")
struct Share2StateTests1 {
    let model = Model.shared
    
    @Test func checkInitialResultValue() {
        #expect(model.result == 0)
    }
    
    @Test func checkAddValue() {
        #expect(model.add(5) == 5)
        #expect(model.add(3) == 8)
    }
    
    @Test func checkSubtractValue() {
        _ = model.add(5)
        #expect(try! model.subtract(3) == 2)
    }
    
    @Test func checkSubtractThrowsOnNegativeResult() throws {
        #expect(throws: ModelErrors.negativeResult) {
            try _ = model.subtract(3)
        }
    }
    
    @Test func checkClear() {
        #expect(model.add(5) == 5)
        #expect(model.clear() == 0)
    }
}
