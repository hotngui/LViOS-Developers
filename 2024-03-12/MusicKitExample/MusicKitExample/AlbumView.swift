//
// Created by Joey Jarosz on 3/9/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Kingfisher
import MusicKit
import SwiftUI

/// Displays an Album with its artwork and its list of tracks
///
struct AlbumView: View {
    @Environment(\.dismiss) var dismiss
    
    enum Constants {
        static let width = 1000.0
        static let height = 1000.0
    }
    
    enum PlayState {
        case play, pause
    }

    var album: Album
    
    @State private var tracks: MusicItemCollection<Track>?
    @State private var selection: Track? = nil
    
    @State private var isPlaybackQueueSet = false
    @State private var isShowingSubscriptionOffer = false

    @State private var musicSubscription: MusicSubscription?
    @State private var offerOptions: MusicSubscriptionOffer.Options = .default

    @State private var playState: PlayState = .play
    
    private let player = ApplicationMusicPlayer.shared
    
    private var isPlaying: Bool {
        return (player.state.playbackStatus == .playing)
    }
   
    /// We should be checking for `canBecomeSubscriber` instead but for some reason I never get the expected value on my test devices.
    private var shouldOfferSubscription: Bool {
        return !(musicSubscription?.canPlayCatalogContent ?? false)
    }
    
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

// This is here just to eliminate Kingfisher as an issue with things getting resized after this view is displayed as a sheet...
//
//                    AsyncImage(url: album.artwork?.url(width: Int(Constants.width), height: Int(Constants.height))) { image in
//                        image
//                            .resizable()
//                            .frame(maxWidth: .infinity)
//                            .aspectRatio(1.0, contentMode: .fit)
//                    } placeholder: {
//                        Image(systemName: "music.note")
//                            .font(.largeTitle)
//                            .foregroundStyle(.gray)
//                    }

                    KFImage
                        .url(album.artwork?.url(width: Int(Constants.width), height: Int(Constants.height)))
                        .placeholder {
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                        .fade(duration: 1.45)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                
                HStack {
                    if shouldOfferSubscription {
                        Button(action: handleOfferButton) {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Join")
                            }
                            .frame(maxWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    else {
                        Button(action: handlePlayButton) {
                            switch playState {
                            case .play:
                                Label("Play", systemImage: "play.circle")
                            case .pause:
                                Label("Pause", systemImage: "pause.circle")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isPlaybackQueueSet == false)
                        .animation(.easeInOut(duration: 0.1), value: isPlaying)
                    }
                }
                
                if let tracks {
                    List(tracks, id: \.self, selection: $selection) { track in
                        TrackRowView(track: track)
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                }
            }
            .navigationTitle(album.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            handleSelectionChange(oldValue: oldValue, newValue: newValue)
        }
        .task {
            // Request track details for the album...
            await loadTracks()

            // Keep track up Music subscription in case it changes, like if the user takes advantage of
            // the Trial Offer that we present from Apple...
            for await subscription in MusicSubscription.subscriptionUpdates {
                musicSubscription = subscription
            }
        }
        .musicSubscriptionOffer(isPresented: $isShowingSubscriptionOffer, options: offerOptions)
    }
    
    // MARK: - MusicKit Handlers
    
    
    /// As the `album` to retrieve its details, which in this case the list of artists and tracks belonging to it...
    ///
    @MainActor private func loadTracks() async {
        let detailedAlbum = try? await album.with([.artists, .tracks])
        self.tracks = detailedAlbum?.tracks
    }
    
    // MARK: - Utilities Methods
    
    /// Updates the `play` state when the user taps the button as well as starting or pausing the music player
    ///
    private func handlePlayButton() {
        Task {
            if isPlaying {
                player.pause()
                playState = .play
            } else {
                try? await player.play()
                playState = .pause
                
            }
        }
    }
    
    /// Configures the trial offer we want to present to the user when they do not currently have a subscription...
    ///
    private func handleOfferButton() {
        offerOptions.messageIdentifier = .playMusic
        offerOptions.itemID = album.id
        isShowingSubscriptionOffer = true
    }
    
    /// Update the current selection, and if we are currently playing a track we pause it and start playing the newly selected track
    ///
    /// - Parameters:
    ///   - oldValue: the old selected track, if one exists
    ///   - newValue: the newly selected track, if one exists
    ///
    private func handleSelectionChange(oldValue: Track?, newValue: Track?) {
        if let newValue, let tracks {
            let localIsPlaying = isPlaying
            
            if localIsPlaying {
                player.pause()
            }
            
            player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: newValue)
            isPlaybackQueueSet = true
            
            if localIsPlaying {
                Task {
                    try? await player.play()
                }
            }
        }
    }
}

//#Preview {
//    AlbumView()
//}
