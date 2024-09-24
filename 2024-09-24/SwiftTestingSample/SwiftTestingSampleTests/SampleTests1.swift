//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SwiftTestingSample

@Suite("1st Group of Sample Tests")
struct SomeSimpleTests1 {
    @Test("Test Level Display Name 1", .tags(.example1))
    func example1() {
        let model = Model()
        #expect(model.result == 0)
    }

    @Test("Test Level Display Name 2", .tags(.example2), .disabled())
    func example2() {
        let model = Model()
        #expect(model.result == 1)
    }
}
