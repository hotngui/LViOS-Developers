//
// Created by Joey Jarosz on 12/13/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Download Files", systemImage: "tray.and.arrow.down") {
                DownloadView()
            }
            Tab("Upload Files", systemImage: "tray.and.arrow.up") {
                UploadView()
            }
        }
        .task {
            Notifications.requestNotificationAuthorization()
        }
    }
}

#Preview {
    ContentView()
        .environment(FileHandler())
}
