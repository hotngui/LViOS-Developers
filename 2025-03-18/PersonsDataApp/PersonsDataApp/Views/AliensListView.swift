import SwiftUI

struct AliensListView: View {
    @State private var service: PersonRetrievable
    @State private var aliens: [Alien] = []
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
                    Text("Loading Aliens...")
                }
            } else if let error {
                ContentUnavailableView {
                    Label("Could Not Load Aliens", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Try Again") {
                        Task {
                            await loadAliens()
                        }
                    }
                }
            } else {
                List(aliens.sorted(by: { $0.lastName < $1.lastName })) { alien in
                    AlienView(alien: alien)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }                            
                }
            }
        }
        .navigationTitle("Aliens")
        .task {
            await loadAliens()
        }
        .refreshable {
            await loadAliens()
        }
    }
    
    private func loadAliens() async {
        do {
            error = nil
            aliens = try await service.fetchAliens()
        } catch {
            self.error = error
            aliens = []
        }
    }
}

#Preview("With Data") {
    NavigationStack {
        AliensListView(service: MockAlienRetrieveService())
    }
}

#Preview("With Error") {
    NavigationStack {
        AliensListView(service: MockAlienRetrieveService(shouldError: true))
    }
}

// MARK: - Mock Service for Preview
class MockAlienRetrieveService: PersonRetrievable {
    var isLoading = false
    private let shouldError: Bool
    
    init(shouldError: Bool = false) {
        self.shouldError = shouldError
    }
    
    func fetchAliens() async throws -> [Alien] {
        isLoading = true
        defer { isLoading = false }
        
        if shouldError {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock network error"])
        }
        
        return [
            Alien(
                firstName: "Zorg",
                lastName: "Xylophone",
                planet: "Galaxy X23, Sector 7, Planet Z",
                avatarURL: URL(string: "https://picsum.photos/200")
            ),
            Alien(
                firstName: "Blip",
                lastName: "Blorp",
                planet: "Nebula N42, Quadrant Q, Planet X",
                avatarURL: URL(string: "https://picsum.photos/201")
            ),
            Alien(
                firstName: "Qwix",
                lastName: "Andromeda",
                planet: "Andromeda Galaxy, System Y, Planet K",
                avatarURL: nil
            )
        ]
    }
    
    func fetchPersons() async throws -> [Person] {
        []
    }
}
