//
// Created by Joey Jarosz on 10/10/23.
//

import SwiftUI

///
struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var model: DataModel
    @State private var isStatsOpen = false

    var body: some View {
        NavigationStack {
            VStack {
                List(model.paths.indices, id: \.self) { indx in
                    PhotoView(model.paths[indx], indx: indx)
                }
                .listStyle(PlainListStyle())
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close", role: .cancel) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Dump Stats") {
                            isStatsOpen = true
                        }
                    }
                }
                .navigationTitle("Photos")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $isStatsOpen) {
            NavigationStack {
                StatsView(data: Cache.default.dumpStats(photoCount: MainViewController.getPhotoCount(),
                                                        imageSize: MainViewController.getImageSize(),
                                                        toolkit: MainViewController.getToolkitValue()))
            }
        }
    }
    
    init(_ model: DataModel) {
        self.model = model
    }
}

#Preview {
    let model = DataModel()
    model.paths = ImageProvider.default.urls(first: 5, at: .high)
    
    return PhotoViewer(model)
}
