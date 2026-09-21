//
// Created by Joey Jarosz on 9/20/26.
//

import Foundation

/// The user's tunable settings, persisted to `UserDefaults` and shared with every screen
/// via the SwiftUI environment. Storage keys and string values match the pre-SwiftUI
/// version of the app so existing installs keep their settings.
@MainActor
@Observable
final class AppSettings {
    enum ImageSize: String, CaseIterable {
        case medium = "Medium"
        case large = "Large"

        var resolution: ImageProvider.Resolution {
            switch self {
            case .medium: .medium
            case .large: .high
            }
        }
    }

    private enum Property: String {
        case photoCount
        case imageSize
        case toolkit
        case cacheType
        case requestMode
    }

    let maxPhotoCount = ImageProvider.default.maxCount

    var photoCount: Int {
        didSet { UserDefaults.standard.set(photoCount, forKey: Property.photoCount.rawValue) }
    }

    var imageSize: ImageSize {
        didSet { UserDefaults.standard.set(imageSize.rawValue, forKey: Property.imageSize.rawValue) }
    }

    var requestMode: ImageRequestMode {
        didSet { UserDefaults.standard.set(requestMode.rawValue, forKey: Property.requestMode.rawValue) }
    }

    /// The image URLs matching the current photo count and image size settings.
    var imagePaths: [String] {
        ImageProvider.default.urls(first: photoCount, at: imageSize.resolution)
    }

    init() {
        let defaults = UserDefaults.standard
        let maxCount = ImageProvider.default.maxCount
        let storedCount = defaults.integer(forKey: Property.photoCount.rawValue)

        photoCount = (storedCount > 0) ? min(storedCount, maxCount) : maxCount

        if let value = defaults.string(forKey: Property.imageSize.rawValue), let size = ImageSize(rawValue: value) {
            imageSize = size
        } else {
            imageSize = .large
        }

        if let value = defaults.string(forKey: Property.requestMode.rawValue), let mode = ImageRequestMode(rawValue: value) {
            requestMode = mode
        } else {
            requestMode = .httpRules
        }

        // The "toolkit" setting went away when the UIKit photo viewer was removed,
        // and "cacheType" went away with the move from Kingfisher to AsyncImage.
        defaults.removeObject(forKey: Property.toolkit.rawValue)
        defaults.removeObject(forKey: Property.cacheType.rawValue)
    }
}
