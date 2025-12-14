//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Displays a single search history item
struct SearchHistoryRow: View {
    let searchTerm: String

    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)

            Text(searchTerm)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        SearchHistoryRow(searchTerm: "Margarita")
        SearchHistoryRow(searchTerm: "Mojito")
        SearchHistoryRow(searchTerm: "Old Fashioned")
    }
}
