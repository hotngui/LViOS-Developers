//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Kingfisher
import SwiftUI

@main
struct SplitView2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        configureKingfisher()
    }
    
    private func configureKingfisher() {
        let cache = ImageCache.default
        let diskSizeLimit = UInt(Measurement<UnitInformationStorage>(value: 500, unit: .megabytes).converted(to: .bytes).value)

        // Configure the storage to you disk...
        cache.memoryStorage.config.totalCostLimit = 1
        cache.memoryStorage.config.countLimit = 1
        cache.diskStorage.config.expiration = .days(7)
        cache.diskStorage.config.sizeLimit = diskSizeLimit

        // Additional options for all typical calls...
        KingfisherManager.shared.defaultOptions += [
            .backgroundDecode,
            .downloadPriority(URLSessionTask.lowPriority)
        ]
    }
}
