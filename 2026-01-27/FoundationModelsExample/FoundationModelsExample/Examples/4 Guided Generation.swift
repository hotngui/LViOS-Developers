//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct GuidedGeneration: View {
    @Environment(FoundationManager.self) var foundationManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedState = "Nevada"
    @State private var response = [StateFact]()
    @State private var isError = false

    private let session = LanguageModelSession(instructions: Instructions {
        "You are an experienced research librarian."
        "Your speciality is retrieving information about the states."
    })

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
                response = []
                isError = false

                let prompt = Prompt {
                    "I want to know more about \(selectedState) so tell me some interesting facts about it."
                    "Provide results that would be interesting to someone who might be looking to move to the state."
                    "Alway include at least 4 fun facts such as the state bird, state flower, and other fun facts."
                }

                let stream = session.streamResponse(to: prompt, generating: [StateFact].self)

                Task {
                    do {
                        for try await partial in stream {
                            response = partial.content.compactMap { partialFact in
                                guard let name = partialFact.name, let details = partialFact.details else {
                                    return nil
                                }
                                return StateFact(name: name, details: details)
                            }
                        }
                    } catch {
                        response = [StateFact(name: "Error:", details: error.localizedDescription)]
                        isError = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(session.isResponding)

            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(response) { fact in
                            FactView(fact: fact)
                                .foregroundStyle(isError ? .red : .primary)
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
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

/// A view that displays a single fact about a US state.
///
/// `FactView` presents a ``StateFact`` with its name displayed in bold,
/// followed by the details and a divider to separate it from other facts.
///
/// ```swift
/// FactView(fact: StateFact(name: "State Bird", details: "Mountain Bluebird"))
/// ```
///
/// - Note: This view is typically used within a `ForEach` to display
///   multiple facts in a scrollable list.
struct FactView: View {
    /// The fact to display in this view.
    let fact: StateFact

    var body: some View {
        VStack(alignment: .leading) {
            Text(fact.name)
                .bold()
            Text(fact.details)
            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        GuidedGeneration()
            .environment(FoundationManager())
            .navigationTitle(ViewOption.fourth.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}

#Preview {
    FactView(fact: .init(name: "Hello", details: "Hello World!"))
}
