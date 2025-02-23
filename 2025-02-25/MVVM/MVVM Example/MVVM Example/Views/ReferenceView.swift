//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct ReferenceView: View {
    private(set) var viewModel: ViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<viewModel.itemIds.count, id: \.self) { indx in
                    let id = viewModel.itemIds[indx]
                    
                    let lastName = viewModel.lastName(for: id) ?? ""
                    let firstName = viewModel.firstName(for: id) ?? ""
                    let isActive = viewModel.isActive(for: id) ?? false
                    
                    HStack {
                        Text("\(lastName), \(firstName)")
                        Spacer()
                        Text(isActive ? "IsActive" : "")
                    }
                }
            }
            .navigationTitle("Reference")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MyData.self, configurations: config)

    for item in MyData.sampleData {
        container.mainContext.insert(item)
    }

    return ReferenceView(viewModel: ViewModel(modelContext: container.mainContext))
        .modelContainer(container)
}
