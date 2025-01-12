//
// Created by Joey Jarosz on 1/12/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct CompactView: View {
    @State private var rotate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MyMap()
                    .opacity(rotate ? 0 : 1)

                MyOther()
                    .opacity(rotate ? 1 : 0)
                    .rotation3DEffect(Angle(degrees: 180.0), axis: (x: 0, y: 1, z: 0))
            }
            .rotation3DEffect(Angle(degrees: rotate ? 180.0 : 0), axis: (x: 0, y: 1, z: 0))
            
            .navigationTitle("Split View 2")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Flip") {
                        withAnimation {
                            rotate.toggle()
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}
