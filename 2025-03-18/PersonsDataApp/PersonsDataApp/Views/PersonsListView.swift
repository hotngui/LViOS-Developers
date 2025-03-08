//
// Created by Joey Jarosz on 3/3/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import SwiftUI

struct PersonsListView: View {
    @State private var service: PersonRetrievable
    @State private var persons: [Person] = []
    @State private var error: Error?
    
    init(service: PersonRetrievable = PersonRetrieveService()) {
        _service = State(initialValue: service)
    }
    
    var body: some View {
        Group {
            if service.isLoading {
                ContentUnavailableView {
                    ProgressView()
                        .controlSize(.large)
                } description: {
                    Text("Loading Persons...")
                }
            } else if let error {
                ContentUnavailableView {
                    Label("Could Not Load Persons", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await loadPersons()
                        }
                    }
                }
            } else {
                List(persons.sorted(by: { $0.lastName < $1.lastName })) { person in
                    PersonView(person: person)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }                            
                }
            }
        }
        .navigationTitle("Persons")
        .task {
            await loadPersons()
        }
        .refreshable {
            await loadPersons()
        }
    }
    
    private func loadPersons() async {
        do {
            error = nil
            persons = try await service.fetchPersons()
        } catch {
            self.error = error
            persons = []
        }
    }
}

#Preview("With Data") {
    NavigationStack {
        PersonsListView(service: MockPersonRetrieveService())
    }
}

#Preview("With Error") {
    NavigationStack {
        PersonsListView(service: MockPersonRetrieveService(shouldError: true))
    }
}

// MARK: - Mock Service for Preview
class MockPersonRetrieveService: PersonRetrievable {
    var isLoading = false
    private let shouldError: Bool
    
    init(shouldError: Bool = false) {
        self.shouldError = shouldError
    }
    
    func fetchPersons() async throws -> [Person] {
        isLoading = true
        defer { isLoading = false }
        
        if shouldError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock network error"])
        }
        
        return [
            Person(
                firstName: "Johnnie",
                lastName: "Appleseed",
                address: "123 Main St, New York, NY",
                avatarURL: URL(string: "https://picsum.photos/200")
            ),
            Person(
                firstName: "George",
                lastName: "Rose",
                address: "456 Oak Ave, San Francisco, CA",
                avatarURL: URL(string: "https://picsum.photos/201")
            ),
            Person(
                firstName: "Bob",
                lastName: "Barker",
                address: "789 Pine St, Chicago, IL",
                avatarURL: nil
            )
        ]
    }
    
    func fetchAliens() async throws -> [Alien] {
        []
    }

}
