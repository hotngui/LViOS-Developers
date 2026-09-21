//
// Created by Joey Jarosz on 10/11/23.
//

import SwiftUI

/// A simple two-column dump of the cache's current configuration and usage statistics.
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss

    let data: [(String, String)]

    let columns = [
        GridItem(.flexible(minimum: 40, maximum: 140), alignment: .trailing),
        GridItem(.flexible(), alignment: .leading)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        if item.1.count > 0 {
                            Text(item.0)
                                .font(.caption)
                                .bold()
                        } else {
                            Text(item.0)
                                .font(.callout)
                                .bold()
                        }

                        Text(item.1)
                    }
                }
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done", role: .cancel) {
                            dismiss()
                        }
                    }
                }
                .navigationTitle("Stats")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#if DEBUG
#Preview {
    return StatsView(data: [
        ("Cache", "AsyncImage + URLCache"),
        ("Request Mode", "HTTP Rules"),
        ("", ""),
        ("Memory  ", ""),
        ("Cost Limit:", "5177507784"),
        ("Count Limit:", "9223372036854775807"),
        ("Expiration", "seconds(300.0)"),
        ("Keep Background", "false"),
        ("Clean Interval", "120.0"),
    ])
}
#endif
