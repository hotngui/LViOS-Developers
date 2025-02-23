//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    private(set) var viewModel: ViewModel
    private(set) var id: UUID
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                let lastName = viewModel.lastName(for: id) ?? ""
                let firstName = viewModel.firstName(for: id) ?? ""

                Text("\(lastName), \(firstName)")
                    .font(.title3)
                    .bold()
                
                Toggle("", isOn: Binding(
                    get: { viewModel.isActive(for: id)! },
                    set: { _,_ in viewModel.toggleItemStatus(id: id) }
                ))
                .labelsHidden()
            }
        }
        .navigationTitle("Details")
    }
}
