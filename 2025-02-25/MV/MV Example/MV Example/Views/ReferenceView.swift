//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ReferenceView: View {
    private(set) var items: [MyData]
    
    var body: some View {
        NavigationStack {
            List(items) { item in
                HStack {
                    Text("\(item.lastName), \(item.firstName)")
                    Spacer()
                    Text(item.isActive ? "IsActive" : "")
                }
            }
            .navigationTitle("Reference ")
        }
    }
} 

#Preview {
    ReferenceView(items: MyData.sampleData)
}
