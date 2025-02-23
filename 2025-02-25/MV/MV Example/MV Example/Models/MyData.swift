import Foundation
import Observation

@Observable
final class MyData: Identifiable {
    let id = UUID()
    var lastName: String
    var firstName: String
    var isActive: Bool
    
    init(firstName: String, lastName: String, isActive: Bool) {
        self.firstName = firstName
        self.lastName = lastName
        self.isActive = isActive
    }
    
    static var sampleData: [MyData] = [
        MyData(firstName: "John", lastName: "Doe", isActive: false),
        MyData(firstName: "Jane", lastName: "Smith", isActive: false),
        MyData(firstName: "Bob", lastName: "Wilson", isActive: false),
        MyData(firstName: "Alice", lastName: "Brown", isActive: false),
        MyData(firstName: "Charlie", lastName: "Davis", isActive: false),
        MyData(firstName: "Emma", lastName: "White", isActive: false),
        MyData(firstName: "David", lastName: "Miller", isActive: false),
        MyData(firstName: "Sarah", lastName: "Johnson", isActive: false),
        MyData(firstName: "Michael", lastName: "Lee", isActive: false),
        MyData(firstName: "Lisa", lastName: "Anderson", isActive: false)
    ]
} 
