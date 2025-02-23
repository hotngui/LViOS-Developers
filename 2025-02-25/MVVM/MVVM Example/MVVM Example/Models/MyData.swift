//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class MyData {
    var id: UUID
    var firstName: String
    var lastName: String
    var isActive: Bool
    
    init(firstName: String, lastName: String, isActive: Bool = false) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.isActive = isActive
    }
    
    static var sampleData: [MyData] = [
        MyData(firstName: "John", lastName: "Doe"),
        MyData(firstName: "Jane", lastName: "Smith"),
        MyData(firstName: "Bob", lastName: "Wilson"),
        MyData(firstName: "Alice", lastName: "Brown"),
        MyData(firstName: "Charlie", lastName: "Davis"),
        MyData(firstName: "Emma", lastName: "White"),
        MyData(firstName: "David", lastName: "Miller"),
        MyData(firstName: "Sarah", lastName: "Johnson"),
        MyData(firstName: "Michael", lastName: "Lee"),
        MyData(firstName: "Lisa", lastName: "Anderson")
    ]
}
