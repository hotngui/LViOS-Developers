//
// Created by Joey Jarosz on 12/7/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import Kingfisher

public struct WrongView: View {
    var maxCount: Int = 2000
    @State var isOpen: Bool = false
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach((1...maxCount), id: \.self) { indx in
                        VStack(alignment: .leading) {
                            MyImageView(indx: indx)
                            Text("Photo \(indx)")
                        }
                        .padding()
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Wrong Way")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    WrongView(maxCount: 5)
}

