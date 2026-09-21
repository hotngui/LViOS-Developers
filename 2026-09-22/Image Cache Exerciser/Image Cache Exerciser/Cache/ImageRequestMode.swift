//
// Created by Joey Jarosz on 9/20/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//
// Lifted from a YouTube video by Stewart Lynch...

import Foundation

/// The user-selectable image caching strategies, each mapping to a
/// `URLRequest.CachePolicy` applied to every image request.
enum ImageRequestMode: String, CaseIterable, Identifiable {
    /// Follow normal HTTP freshness rules (`.useProtocolCachePolicy`).
    case httpRules
    /// Prefer cached data, loading from the network only on a miss (`.returnCacheDataElseLoad`).
    case cacheFirst
    /// Always load from the server, ignoring the local cache (`.reloadIgnoringLocalCacheData`).
    case reload
    /// Use cached data only; fail if it's not cached (`.returnCacheDataDontLoad`).
    case cacheOnly

    var id: Self { self }

    /// Short display name for pickers.
    var title: String {
        switch self {
        case .httpRules: "HTTP Rules"
        case .cacheFirst: "Cache First"
        case .reload: "Reload"
        case .cacheOnly: "Cache Only"
        }
    }

    /// The `URLRequest.CachePolicy` this mode applies to image requests.
    var cachePolicy: URLRequest.CachePolicy {
        switch self {
        case .httpRules: .useProtocolCachePolicy
        case .cacheFirst: .returnCacheDataElseLoad
        case .reload: .reloadIgnoringLocalCacheData
        case .cacheOnly: .returnCacheDataDontLoad
        }
    }

    /// A one-sentence, user-facing description of the mode's behavior.
    var explanation: String {
        switch self {
        case .httpRules:
            "Use normal HTTP freshness and validation rules."
        case .cacheFirst:
            "Use cached data when available; otherwise load it."
        case .reload:
            "Ignore locally cached data and load from the server."
        case .cacheOnly:
            "Use cached data only and fail when it is unavailable."
        }
    }
}
