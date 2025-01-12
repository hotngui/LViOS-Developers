//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 . All rights reserved.
//

import SwiftUI

struct Progress: View {
    var body: some View {
        VStack {
            ProgressView(value: 2.5, total: 3.0)
            
            HStack {
                Text("0:00")
                Spacer()
                Text("3:00")
            }
        }
    }
}

#Preview {
    Progress()
}
