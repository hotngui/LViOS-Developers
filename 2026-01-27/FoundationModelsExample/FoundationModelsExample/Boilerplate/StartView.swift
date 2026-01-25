//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct StartView: View {
    @State private var viewOption: ViewOption = .first
    
    var body: some View {
        NavigationStack {
            viewOption
                .navigationTitle(viewOption.title)
                .toolbarTitleDisplayMode(.inlineLarge)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Picker("View Option", selection: $viewOption) {
                    ForEach(ViewOption.allCases) { viewCase in
                        Text(viewCase.title)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    StartView()
}
