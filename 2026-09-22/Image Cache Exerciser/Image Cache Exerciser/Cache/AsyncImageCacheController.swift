//
// Created by Joey Jarosz on 9/20/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//
// Lifted from a YouTube video by Stewart Lynch...

import Foundation

/// An observable wrapper around a `URLCache` that lets the UI clear the cache
/// and watch its on-disk footprint.
@Observable
class AsyncImageCacheController {
    private let cache: URLCache
    private let cacheDirectory: URL

    /// The cache's current on-disk size in bytes. Refreshed on init, after
    /// ``clearCache()``, on demand via ``refreshDiskUsage()``, and continuously
    /// by ``monitorDiskUsage()``.
    private(set) var diskUsage = 0


    /// Creates a controller for the given cache.
    /// - Parameters:
    ///   - cache: The `URLCache` to manage.
    ///   - cacheDirectory: The cache's on-disk location (logged for debugging).
    init(cache: URLCache, cacheDirectory: URL) {
        self.cache = cache
        self.cacheDirectory = cacheDirectory
        refreshDiskUsage()

        print("AsyncImage cache Location:")
        print(cacheDirectory.path(percentEncoded: false))
    }

    /// Re-reads ``diskUsage`` from the cache. Call before reporting stats.
    func refreshDiskUsage() {
        diskUsage = cache.currentDiskUsage
    }

    /// Removes all cached responses and refreshes ``diskUsage``.
    func clearCache() {
        cache.removeAllCachedResponses()
        refreshDiskUsage()
    }

    /// ``diskUsage`` formatted as a human-readable byte count (e.g. "1.2 MB").
    var formattedDiskUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(diskUsage), countStyle: .file)
    }

    /// The cache's maximum disk capacity as a human-readable byte count.
    var formattedDiskCapacity: String {
        ByteCountFormatter.string(fromByteCount: Int64(cache.diskCapacity), countStyle: .file)
    }

    /// Refreshes ``diskUsage`` every 250 ms until the surrounding task is
    /// cancelled. Run it from a `.task` modifier while stats are visible.
    func monitorDiskUsage() async {
        while !Task.isCancelled {
            refreshDiskUsage()

            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return
            }
        }
    }
}
