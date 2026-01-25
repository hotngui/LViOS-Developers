//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct Basics: View {
    @Environment(FoundationManager.self) var foundationManager

    @State private var prompt = ""
    @State private var response = ""
    @State private var isError = false

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
            TextField("Question", text: $prompt)
                .textFieldStyle(.roundedBorder)

            Button("Response") {
                response = ""
                isError = false

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
            .disabled(prompt.isEmpty)

            ScrollView {
                Text(response)
                    .foregroundStyle(isError ? .red : .primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        Basics()
            .environment(FoundationManager())
            .navigationTitle(ViewOption.first.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
