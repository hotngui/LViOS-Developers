# Swift 6.2 Patterns Used in Cocktail Search App

This document highlights the modern Swift 6.2 and SwiftUI patterns implemented in this project.

## @Observable Macro (Swift 6.2)

**Old Pattern (ObservableObject):**
```swift
class ViewModel: ObservableObject {
    @Published var state: String = ""
}
```

**New Pattern (Used in this app):**
```swift
@Observable
@MainActor
final class CocktailSearchViewModel {
    var searchState: SearchState = .idle
    var showResults = false
}
```

**Benefits:**
- Better performance
- No need for @Published
- Automatic observation
- Cleaner syntax

## Actor for Thread Safety

**Used in CocktailService.swift:**
```swift
actor CocktailService {
    func searchCocktails(by searchTerm: String) async throws -> [Cocktail] {
        // Actor ensures thread-safe access
    }
}
```

**Why:**
- Prevents data races
- Swift 6 concurrency safety
- Isolated state

## Sendable Conformance

**All Models:**
```swift
struct Cocktail: Codable, Identifiable, Sendable {
    let idDrink: String
    // ...
}

enum CocktailServiceError: LocalizedError, Sendable {
    // ...
}

enum SearchState: Sendable {
    // ...
}
```

**Why:**
- Required for Swift 6 strict concurrency
- Ensures types can safely cross concurrency boundaries
- Compile-time safety

## Async/Await (Not Completion Handlers)

**Old Pattern:**
```swift
func search(completion: @escaping (Result<[Cocktail], Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        // callback hell
    }.resume()
}
```

**New Pattern (Used in this app):**
```swift
func searchCocktails(by searchTerm: String) async throws -> [Cocktail] {
    let (data, response) = try await URLSession.shared.data(from: url)
    let searchResponse = try JSONDecoder().decode(CocktailSearchResponse.self, from: data)
    return searchResponse.drinks ?? []
}
```

**Benefits:**
- Linear code flow
- Better error handling
- No callback nesting
- Structured concurrency

## MainActor for UI Operations

**ViewModel:**
```swift
@Observable
@MainActor
final class CocktailSearchViewModel {
    // All properties and methods run on main thread
}
```

**View Calls:**
```swift
Button {
    Task {
        await viewModel.search(for: searchText)
    }
} label: {
    Text("Search")
}
```

**Why:**
- UI updates must be on main thread
- Prevents threading issues
- Explicit about actor context

## Structured Concurrency with Task

**In Views:**
```swift
private func performSearch() {
    Task {
        await viewModel.search(for: searchText)
    }
}
```

**Why:**
- Proper task lifecycle
- Cancellation support
- Scoped concurrency

## Modern SwiftUI Patterns

### @State for Local State
```swift
struct CocktailSearchView: View {
    @State private var viewModel = CocktailSearchViewModel()
    @State private var searchText = ""
}
```

### Sheet Presentation
```swift
.sheet(isPresented: $viewModel.showResults) {
    CocktailResultsView(
        cocktails: viewModel.cocktails,
        onDismiss: { viewModel.dismissResults() }
    )
}
```

### LazyVStack for Performance
```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(cocktails) { cocktail in
            CocktailCardView(cocktail: cocktail)
        }
    }
}
```

## Kingfisher Integration

**Image Loading:**
```swift
import Kingfisher

KFImage(cocktail.thumbnailURL)
    .placeholder {
        Rectangle().fill(Color.gray.opacity(0.2))
            .overlay { ProgressView() }
    }
    .resizable()
    .aspectRatio(contentMode: .fill)
```

**Benefits:**
- Automatic caching
- Placeholder support
- Memory management
- Network efficiency

## Error Handling with Result Builders

**Custom Errors:**
```swift
enum CocktailServiceError: LocalizedError, Sendable {
    case networkError(String)
    case decodingError
    case noResults
    case invalidSearchTerm

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode the response"
        case .noResults:
            return "No cocktails found"
        case .invalidSearchTerm:
            return "Please enter a valid search term"
        }
    }
}
```

**Usage:**
```swift
do {
    let cocktails = try await service.searchCocktails(by: searchTerm)
    searchState = .success(cocktails)
} catch let error as CocktailServiceError {
    searchState = .error(error.localizedDescription)
} catch {
    searchState = .error("An unexpected error occurred")
}
```

## Safe Optional Handling (No Force Unwraps)

**URL Construction:**
```swift
var thumbnailURL: URL? {
    guard let urlString = strDrinkThumb else { return nil }
    return URL(string: urlString)
}
```

**Usage in View:**
```swift
if let imageURL = cocktail.thumbnailURL {
    KFImage(imageURL)
        // ...
} else {
    // Fallback placeholder
}
```

## Computed Properties for Clean Code

**ViewModel:**
```swift
var isLoading: Bool {
    if case .loading = searchState {
        return true
    }
    return false
}

var cocktails: [Cocktail] {
    if case .success(let drinks) = searchState {
        return drinks
    }
    return []
}
```

## UserDefaults with Codable

**History Persistence:**
```swift
private func saveSearchHistory() {
    if let encoded = try? JSONEncoder().encode(searchHistory) {
        UserDefaults.standard.set(encoded, forKey: "searchHistory")
    }
}

private func loadSearchHistory() {
    if let data = UserDefaults.standard.data(forKey: "searchHistory"),
       let decoded = try? JSONDecoder().decode([String].self, from: data) {
        searchHistory = decoded
    }
}
```

## Enum-Based State Management

```swift
enum SearchState: Sendable {
    case idle
    case loading
    case success([Cocktail])
    case error(String)
}
```

**Pattern Matching:**
```swift
switch viewModel.searchState {
case .idle:
    // Initial state
case .loading:
    ProgressView()
case .success(let cocktails):
    // Display results
case .error(let message):
    // Show error
}
```

## Summary of Swift 6.2 Improvements Used

1. **@Observable**: Modern observation without @Published
2. **Actor**: Thread-safe services
3. **Sendable**: Concurrency safety
4. **Async/await**: Clean asynchronous code
5. **MainActor**: Explicit UI thread operations
6. **Structured concurrency**: Task-based async execution
7. **No force unwraps**: Safe optional handling
8. **Codable**: Type-safe JSON encoding/decoding
9. **LocalizedError**: User-friendly error messages
10. **Modern SwiftUI**: Latest view modifiers and patterns

## Anti-Patterns Avoided

- ObservableObject (use @Observable instead)
- Completion handlers (use async/await)
- Force unwrapping (use safe optionals)
- Main thread violations (use MainActor)
- Data races (use Actor)
- .tabItem for tabs (not needed, use Tab() struct when needed)
- Manual image caching (use Kingfisher)
- Unstructured concurrency (use Task)

## Performance Optimizations

1. **LazyVStack**: Only loads visible items
2. **Kingfisher**: Image caching and memory management
3. **Actor isolation**: Prevents contention
4. **@Observable**: Fine-grained observation
5. **Codable caching**: Fast history persistence

All patterns follow Apple's latest Swift 6.2 guidelines and SwiftUI best practices as of 2025.
