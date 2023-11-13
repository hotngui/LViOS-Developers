//
// Created by Joey Jarosz on 10/11/23.
//

import SwiftUI

///
class StatsViewHostingController: UIHostingController<StatsView> {
    init(data: [(String, String)]) {
        super.init(rootView: StatsView(data: data))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

///
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
                    ForEach(data, id: \.self.0) { item in
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
                    ToolbarItem(placement: .navigationBarTrailing) {
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
        ("Cache", "Kingfisher"),
        ("Type", "Default"),
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
