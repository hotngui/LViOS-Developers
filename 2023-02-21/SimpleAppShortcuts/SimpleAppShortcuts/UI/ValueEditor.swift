//
// Created by Joey Jarosz on 2/19/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ValueEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    @State var valueStr: String = ""
    @State var isErrorOpen = false
    
    @ObservedObject var dataModel: DataModel
    
    var body: some View {
        Form {
            Section {
                TextField("Enter a value here", text: $valueStr, axis: .vertical)
                    .focused($isFocused)
                    .keyboardType(.numberPad)
            } header: {
                Text("Value")
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
                    if let value = Double(valueStr) {
                        dataModel.add(value: value)
                        dismiss()
                    } else {
                        isErrorOpen = true
                    }
                }
                .disabled(valueStr.count == 0)
            }
        }
        .navigationTitle("Data Entry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFocused = true
        }
        .alert("Error", isPresented: $isErrorOpen, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("The value you entered is not a number.")
        })
    }
}

struct ValueEditor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ValueEditor(dataModel: DataModel())
        }
    }
}
