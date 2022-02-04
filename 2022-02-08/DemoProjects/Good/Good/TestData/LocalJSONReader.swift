//
// Created by Joey Jarosz on 2/4/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

///
class LocalJSONReader {
    static func read(from name: String) -> Data? {
        guard let url = Bundle(for: self).url(forResource: name, withExtension: "json") else {
            return nil
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
}

