//
// Created by Joey Jarosz on 9/23/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

enum ModelErrors: Error {
    case negativeResult
}

@Observable
public class Model {
    static let shared = Model()
    var result: Int = 0
    
    public func clear() -> Int {
        result = 0
        return result
    }
    
    public func add(_ value: Int) -> Int {
        result += value
        return result
    }
    
    public func subtract(_ value: Int) throws -> Int {
        let check = result - value
        
        guard check >= 0 else {
            throw ModelErrors.negativeResult
        }
        
        result = check
        return result
    }
}
