//
// Created by Joey Jarosz on 10/4/23.
// 
//

import SwiftUI

/// Notice that the `string` properties of the item
///
struct ContactCard: View {
    let contact: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(contact.lastName), \(contact.firstName)")
                .bold()
            Text("\(contact.street), \(contact.city), \(contact.state) \(contact.zip, format: .number.grouping(.never))")
                .font(.caption)
        }
    }
}

#Preview {
    ContactCard(contact: Item(lastName: "Chai", firstName: "Chunky", street: "177 Monroe Street", city: "Sunnyvale", state: "CA", zip: 95050))
}
