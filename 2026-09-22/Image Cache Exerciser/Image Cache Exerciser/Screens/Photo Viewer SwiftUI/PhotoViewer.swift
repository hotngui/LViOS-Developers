//
// Created by Joey Jarosz on 10/10/23.
//

import SwiftUI

/// A full-screen scrolling list of the photos selected on the main screen.
struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    let paths: [String]

    @State private var isStatsOpen = false

    var body: some View {
        NavigationStack {
            List(Array(paths.enumerated()), id: \.offset) { indx, path in
                PhotoView(path, indx: indx, cachePolicy: settings.requestMode.cachePolicy)
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dump Stats") {
                        isStatsOpen = true
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
        }
        .asyncImageURLSession(ImageNetworking.imageSession)
        .sheet(isPresented: $isStatsOpen) {
            StatsView(data: Cache.default.dumpStats(photoCount: settings.photoCount,
                                                    imageSize: settings.imageSize.rawValue,
                                                    requestMode: settings.requestMode))
        }
    }
}

#Preview {
    PhotoViewer(paths: ImageProvider.default.urls(first: 5, at: .high))
        .environment(AppSettings())
}
