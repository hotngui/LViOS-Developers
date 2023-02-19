//
// Created by Joey Jarosz on 1/14/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct DataValue: Identifiable {
    let valueStr: String
    let id = UUID()
}

struct ContentView: View {
    @State var isEditorOpen = false
    
    @ObservedObject var dataModel: DataModel
    
    private var values: [DataValue] {
        dataModel.data.map({ value in
            DataValue(valueStr: "\(value)")
        })
    }
    
    var body: some View {
        NavigationStack {
            Table(values) {
                TableColumn("Value", value: \.valueStr)
            }
            .navigationTitle("Values")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditorOpen = true
                    }) {
                        Label("Add", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditorOpen) {
            NavigationStack {
                ValueEditor(dataModel: dataModel)
            }
        }
    }
    
    init(dataModel: DataModel) {
        self.dataModel = dataModel
        
//        self.values = dataModel.data.map({ value in
//            DataValue(valueStr: "\(value)")
//        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dataModel: DataModel())
    }
}
