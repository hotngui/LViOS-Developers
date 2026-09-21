//
// Created by Joey Jarosz on 9/20/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//
// Lifted from a YouTube video by Stewart Lynch...

import Foundation

/// Namespace for the app's dedicated image-loading network stack: a `URLCache`
/// and a `URLSession` configured to use it.
enum ImageNetworking {
    private static let megabyte = 1_024 * 1_024

    /// The on-disk location of the image cache, a dedicated folder inside the
    /// user's caches directory.
    static let cacheDirectory = URL.cachesDirectory.appending(component: "AsyncImageCachedImages")

    /// The `URLCache` backing all image loads (64 MB memory / 100 MB disk),
    /// stored at ``cacheDirectory``.
    static let imageCache = URLCache(
        memoryCapacity: 64 * megabyte,
        diskCapacity: 100 * megabyte,
        directory: cacheDirectory
    )

    /// A `URLSession` wired to ``imageCache``. Pass it to
    /// `.asyncImageURLSession(_:)` so `AsyncImage` requests go through the
    /// app's own cache instead of the shared one.
    static let imageSession:URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = imageCache
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }()
}
