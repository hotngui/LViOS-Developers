//
// Created by Joey Jarosz on 1/12/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct RegularView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                HStack {
                    MyMap()
                    MyOther()
                        .frame(width: proxy.size.width * 0.3)
                }
                .navigationTitle(Text("Split View 2"))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    RegularView()
}
