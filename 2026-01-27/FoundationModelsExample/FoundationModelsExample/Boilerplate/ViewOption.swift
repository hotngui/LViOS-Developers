//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

enum ViewOption: CaseIterable, Identifiable, View {
    case first, second, third, fourth, fifth, sixth
    var id: Self { self }
    
    var title: String {
        switch self {
        case .first:
            "Basics"
        case .second:
            "Prompt Building"
        case .third:
            "Streaming Results"
        case .fourth:
            "Guided Generation"
        case .fifth:
            "Transcripts"
        case .sixth:
            "Tool"
        }
    }

    var body: some View {
        switch self {
        case .first:
            Basics()
        case .second:
            PromptBuilding()
        case .third:
            StreamingResults()
        case .fourth:
            GuidedGeneration()
        case .fifth:
            Transcripts()
        case .sixth:
            Tools()
        }
    }
}
