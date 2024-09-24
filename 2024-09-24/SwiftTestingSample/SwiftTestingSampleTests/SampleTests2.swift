//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SwiftTestingSample

@Suite("2nd Group of Sample Tests")
struct SomeSimpleTests2 {
    @Test("Test Level Display Name 1", .tags(.example1))
    func example1() {
        #expect(Bool(true))
    }

    @Test("Test Level Display Name 2", .tags(.example2), .disabled())
    func example2() {
        #expect(Bool(false))
    }
}
