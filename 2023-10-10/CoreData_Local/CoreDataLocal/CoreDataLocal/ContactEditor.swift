//
// Created by Joey Jarosz on 10/4/23.
// 
//

import SwiftUI

struct ContactEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var lastName: String
    @State private var firstName: String
    @State private var street: String
    @State private var city: String
    @State private var state: String
    @State private var zip: String
    
    var body: some View {
        Form {
            Section {
                TextField("Last Name", text: $lastName, axis: .vertical)
                TextField("First Name", text: $firstName, axis: .vertical)
            } header: {
                Text("NAME")
                    .accessibility(addTraits: .isHeader)
            }
            
            Section {
                TextField("Street", text: $street, axis: .vertical)
                TextField("City", text: $city, axis: .vertical)
                TextField("State", text: $state, axis: .vertical)
                    .textInputAutocapitalization(.characters)
                TextField("Zip", text: $zip, axis: .vertical)
                    .keyboardType(.numberPad)
            } header: {
                Text("ADDRESS")
                    .accessibility(addTraits: .isHeader)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                    dismiss()
                }
            }
        }
        .navigationTitle("New Contact")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Initializers
    
    init() {
        _lastName = State(initialValue: "")
        _firstName = State(initialValue: "")

        _street = State(initialValue: "")
        _city = State(initialValue: "")
        _state = State(initialValue: "")
        _zip = State(initialValue: "")
    }
    
    // MARK: - Private Methods
    
    private func save() {
        let newItem = Item(context: viewContext)
        newItem.lastName = lastName
        newItem.firstName = firstName
        newItem.street = street
        newItem.city = city
        newItem.state = state
        newItem.zip = Int64(zip) ?? 12345
        
        try? viewContext.save()        
    }
}

#if DEBUG
#Preview {
    ContactEditor()
}
#endif
