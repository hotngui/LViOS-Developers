//
// Created by Joey Jarosz on 3/5/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct NotAuthorizedView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ContentUnavailableView(label: {
            Label(
                title: {
                    Text("Want to search for albums?")
                },
                icon: {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                }
            )
            .padding(20)
        }, description: {
            Text("We need your permission to access Apple Music on your behalf")
        }, actions: {
            Button("Authorize") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        })
    }
}

// MARK: - Previews

#Preview {
    NotAuthorizedView()
}
