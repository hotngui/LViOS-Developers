//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct Tools: View {
    @Environment(FoundationManager.self) var foundationManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedState = "Nevada"
    @State private var response = [StateFact]()
    @State private var isError = false

    private let session = LanguageModelSession(tools: [StateFactTool()], instructions: Instructions {
        "You are a 1% research librarian."
        "Your speciality is retrieving information about the states of the United States."
        "When asked about state facts, always call 'StateFactTool' first to retrieve official state information."
        "Include all facts returned by StateFactTool in your response before adding any additional facts."
        "Do not duplicate or rephrase facts already provided by StateFactTool."
        "Never return more than ten facts."
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
                    "Tell me interesting facts about \(selectedState)."
                    "Include 8 to 10 unique facts covering topics like the state bird, flower, and favorite color."
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


#Preview {
    NavigationStack {
        Tools()
            .environment(FoundationManager())
            .navigationTitle(ViewOption.fourth.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
