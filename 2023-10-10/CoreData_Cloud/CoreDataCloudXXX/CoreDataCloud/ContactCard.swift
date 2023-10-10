//
// Created by Joey Jarosz on 10/8/23.
// Copyright (c) 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Notice that the `string` properties of the item
///
struct ContactCard: View {
    let contact: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(contact.lastName!), \(contact.firstName!)")
                .bold()
            Text("\(contact.street!), \(contact.city!), \(contact.state!) \(contact.zip, format: .number.grouping(.never))")
                .font(.caption)
        }
    }
}

#Preview {
    let viewContext = PersistenceController.preview.container.viewContext
    let contact = Item(context: viewContext)
    
    contact.lastName = "Chai"
    contact.firstName = "Chunky"
    contact.street = "177 Monroe Street"
    contact.city = "Henderson"
    contact.state = "NV"
    contact.zip = 99999
    
    return ContactCard(contact: contact)
}
