//
// Created by Joey Jarosz on 1/25/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// This struct supports the decoding and encoding of arrays of data whilst dropping entries that are not correctly formed. This is not something that
/// you always want to do but it can come in handy when you don't control the contract between the client and server. In cases where its not practical or desired to
/// have data objects that are just a bunch of options this struct provides that extra option.
///
/// Can't take credit for this class as its pretty much lifted from the following blog post.
/// @see: https://www.swiftbysundell.com/articles/ignoring-invalid-json-elements-codable/
///
@propertyWrapper
struct LossyCodableList<Element>: Codable where Element: Codable {
    var elements: [Element]

    var wrappedValue: [Element] {
        get { elements }
        set { elements = newValue }
    }

    private struct ElementWrapper: Codable {
        var element: Element?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            element = try? container.decode(Element.self)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let wrappers = try container.decode([ElementWrapper].self)

        elements = wrappers.compactMap(\.element)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        for element in elements {
            try? container.encode(element)
        }
    }
}
