//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct EditorView: View {
    private(set) var viewModel: ViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<viewModel.itemIds.count, id: \.self) { indx in
                    let id = viewModel.itemIds[indx]
                    
                    let lastName = viewModel.lastName(for: id) ?? ""
                    let firstName = viewModel.firstName(for: id) ?? ""
                    
                    NavigationLink {
                        DetailView(viewModel: viewModel, id: id)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("\(lastName), \(firstName)")
                                .font(.title3)
                                .bold()
                            
                            HStack {
                                Text("Is Active: ")
                                Toggle("", isOn: Binding(
                                    get: { viewModel.isActive(for: id)! },
                                    set: { _,_ in viewModel.toggleItemStatus(id: id) }
                                ))
                                .labelsHidden()
                            }
                            
                        }
                    }
                }
            }
            .navigationTitle("Person Editor")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MyData.self, configurations: config)

    for item in MyData.sampleData {
        container.mainContext.insert(item)
    }

    return EditorView(viewModel: ViewModel(modelContext: container.mainContext))
        .modelContainer(container)
}
