//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct StreamingResults: View {
    @Environment(FoundationManager.self) var foundationManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedState = "Nevada"
    @State private var response = ""
    @State private var isError = false

    private let session = LanguageModelSession()

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                foundationManager.checkIsAvailable()
            }
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

                let stream = session.streamResponse(to: prompt)

                Task {
                    do {
                        for try await partial in stream {
                            withAnimation {
                                response = partial.content
                            }
                        }
                    } catch {
                        response = "Error: \(error.localizedDescription)"
                        isError = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.isResponding)

            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        Text(.init(response))
                            .foregroundStyle(isError ? .red : .primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .onChange(of: response) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(.quinary)
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                if session.isResponding {
                    VStack {
                        ProgressView()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StreamingResults()
            .environment(FoundationManager())
            .navigationTitle(ViewOption.third.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
