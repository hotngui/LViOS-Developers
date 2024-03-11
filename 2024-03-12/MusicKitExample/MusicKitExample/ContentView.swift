//
// Created by Joey Jarosz on 3/4/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import MusicKit


struct ContentView: View {
    @Environment(\.openURL) private var openURL

    @State var musicAuthorizationStatus: MusicAuthorization.Status

    @State var searchText = ""
    @State var albums = [Album]()
    
    @State private var selection: Album? = nil
    @State private var isAlbumSheetShowing = false
    
    var body: some View {
        Group {
            if musicAuthorizationStatus == .authorized {
                NavigationStack {
                    List(albums, id: \.self, selection: $selection) { album in
                        AlbumRowView(album: album)
                    }
                    .onChange(of: selection) { oldValue, newValue in
                        if newValue != nil {
                            isAlbumSheetShowing = true
                        }
                    }
                    .sheet(isPresented: $isAlbumSheetShowing, onDismiss: {
                        selection = nil
                    }, content: {
                        if let selection {
                            AlbumView(album: selection)
                        }
                    })
                    .listStyle(PlainListStyle())
                    .navigationTitle("Album Search")
                }
                .searchable(text: $searchText,
                            placement: .automatic,
                            prompt: "Enter Artist Name")
                .onSubmit(of: .search) {
                    doSearch(for: searchText)
                }
                .onChange(of: searchText, { oldValue, newValue in
                    print("searchText = \(searchText)")
                })
                .overlay {
                    // I'm lazy, so let's just display the default `ContentUnavailableView.search` view...
                    if albums.isEmpty {
                        ContentUnavailableView
                            .search(text: searchText)
                    }
                }
            }
            else {
                NotAuthorizedView()
            }
        }
        .task {
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Initializers
    
    public init(musicAuthorizationStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus) {
        _musicAuthorizationStatus = .init(initialValue: musicAuthorizationStatus)
    }

    // MARK: - MusicKit Handlers
    
    @MainActor
    private func checkAuthorizationStatus() {
        switch musicAuthorizationStatus {
            case .notDetermined:
                Task {
                    let musicAuthorizationStatus = await MusicAuthorization.request()
                    update(with: musicAuthorizationStatus)
                }
            case .denied:
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            case .authorized:
                update(with: .authorized)
            
            default:
                break
        }
    }

    @MainActor
    private func doSearch(for term: String) {
        Task {
            do {
                var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
                request.limit = 25
                let response = try await request.response()
                setAlbums(response.albums)
            } catch {
                setAlbums(MusicItemCollection<Album>())
            }
       }
    }

    @MainActor
    private func setAlbums(_ albums: MusicItemCollection<Album>) {
        withAnimation {
            self.albums = Array(albums)
        }
    }

    @MainActor
    private func update(with musicAuthorizationStatus: MusicAuthorization.Status) {
        withAnimation {
            self.musicAuthorizationStatus = musicAuthorizationStatus
        }
    }
}

// MARK: - Previews

#Preview("Not Determined") {
    ContentView(musicAuthorizationStatus: .notDetermined)
}

#Preview("Authorized") {
    ContentView(musicAuthorizationStatus: .authorized)
}

#Preview("Denied") {
    ContentView(musicAuthorizationStatus: .denied)
}
