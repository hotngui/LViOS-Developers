//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SwiftTestingSample

@Suite("Model Tests")
struct ModelTests {
    @Test func checkInitialResultValue() {
        let model = Model()
        #expect(model.result == 0)
    }
    
    @Test func checkAddValue() {
        let model = Model()
        #expect(model.add(5) == 5)
        #expect(model.add(3) == 8)
    }
    
    @Test func checkSubtractValue() {
        let model = Model()
        _ = model.add(5)
        
        #expect(try! model.subtract(3) == 2)
    }
    
    @Test func checkSubtractThrowsOnNegativeResult() throws {
        #expect(throws: ModelErrors.negativeResult) {
            let model = Model()
            try _ = model.subtract(3)
        }
    }
    
    @Test func checkClear() {
        let model = Model()
        #expect(model.add(5) == 5)
        #expect(model.clear() == 0)
    }
}
