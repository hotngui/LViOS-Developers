//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct PromptBuilding: View {
    @Environment(FoundationManager.self) var foundationManager

    @State private var selectedState = "Alabama"
    @State private var response = ""
    @State private var isError = false
    
    private let states = [
        "Alabama", "Alaska", "Arizona", "Arkansas", "California",
        "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
        "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa",
        "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
        "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
        "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
        "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
        "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
        "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
        "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
    ]

    var body: some View {
        VStack {
            if foundationManager.isModelAvailable {
                realContent
            } else {
                foundationManager.contentUnavailbleView()
            }
        }
        .padding()
        .onAppear() {
            foundationManager.checkIsAvailable()
        }
    }

    @ViewBuilder
    private var realContent: some View {
        VStack {
            Picker("State", selection: $selectedState) {
                ForEach(states, id: \.self) { state in
                    Text(state).tag(state)
                }
            }
            .pickerStyle(.menu)

            Button("Information") {
                response = ""
                isError = false

                let prompt = Prompt {
                    "Provide results that would be interesting to someone who might be looking to move."
                    "I want to know more about \(selectedState)."
                    "Include some fun facts such as the state bird, state flower, and other func facts."
                }

                let session = LanguageModelSession()

                Task {
                    do {
                        response = try await session.respond(to: prompt).content
                    } catch {
                        response = "Error: \(error.localizedDescription)"
                        isError = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(.init(response))
                    .foregroundStyle(isError ? .red : .primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PromptBuilding()
            .environment(FoundationManager())
            .navigationTitle(ViewOption.second.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
