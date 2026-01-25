//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

@Observable
final class FoundationManager {
    var notAvailableReason = "Checking model availability..."

    var isModelAvailable: Bool {
        notAvailableReason.isEmpty
    }

    init() {
        checkIsAvailable()
    }

    @discardableResult
    func checkIsAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            notAvailableReason = ""
        case .unavailable(.appleIntelligenceNotEnabled):
            notAvailableReason = "Enable Apple Intelligence in System Settings."
        case .unavailable(.deviceNotEligible):
            notAvailableReason = "Apple Intelligence is not available on this device."
        case .unavailable(.modelNotReady):
            notAvailableReason = "Model not ready.\nDownloading or temporarily unavailable.\nPlease ensure that you have sufficient battery and Wi-Fi."
        case .unavailable(let unknownReason):
            notAvailableReason = "Foundation Model unavailable: \(String(describing: unknownReason))"
        }

        return isModelAvailable
    }


    @ViewBuilder
    func contentUnavailbleView() -> some View {
        ContentUnavailableView {
            Label("Apple Intelligence is Unavailable", systemImage: "apple.intelligence")
        } description: {
            Text(notAvailableReason)
        } actions: {
            Button("Try Again") { [weak self] in
                self?.checkIsAvailable()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
