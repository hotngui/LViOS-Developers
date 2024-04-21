//
// Created by Joey Jarosz on 3/9/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct DummyView: View {
    @Environment(\.dismiss) var dismiss
    
    var data: String
    var values = ["A", "B", "C", "D", "E"]
        
    ///
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(.gray.opacity(0.1))
                        .stroke(.gray, lineWidth: 2)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    AsyncImage(url: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/f0/7a/54/f07a54ab-3ebc-6813-e515-86200b8138fc/dj.uthntyfe.jpg/1000x1000bb.jpg")!) { image in
                        image
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1.0, contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                    }
                }
                
                HStack {
                    Text("Some Text")
                }
                
                List(values, id: \.self) { track in
                    Text("Value = \(track)")
                }
                .listStyle(.plain)
            }
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
