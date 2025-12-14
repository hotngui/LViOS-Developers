<objective>
Build a complete SwiftUI cocktail search application that allows users to search for cocktails by name using TheCocktailDB API, display results with images in a modal sheet, and maintain a searchable history of previous searches.

This app will demonstrate modern SwiftUI patterns including async networking, state management with @AppStorage, third-party package integration (Kingfisher), and comprehensive error handling.
</objective>

<context>
- Project: Example1 (existing SwiftUI project)
- Target: Latest SwiftUI with Swift 6.2
- API: TheCocktailDB - https://www.thecocktaildb.com/api/json/v1/1/search.php?s={searchTerm}
- User will enter search terms in a text field and view results in a sheet modal
- Search history (last 10 searches) persists between launches using @AppStorage
- Selecting a history item automatically re-executes that search
- Images cached using Kingfisher package for optimal performance

Read the CLAUDE.md file for Swift/SwiftUI coding guidelines and ensure compliance with Swift 6.2 patterns.
</context>

<requirements>

**Core Functionality:**
1. Text field for entering cocktail search terms
2. Search button to trigger API call
3. Display search history (last 10 searches) on main screen
4. Tapping a history item automatically performs that search
5. Sheet modal presentation of search results
6. Display cocktail images, names, and relevant details from API response
7. Persist search history using @AppStorage (survives app restarts)

**Technical Requirements:**
1. Use async/await for API calls (Swift 6.2 structured concurrency)
2. Integrate Kingfisher Swift package for efficient image loading and caching
3. Use Sheet modal (not full-screen cover) for results presentation
4. Implement comprehensive error handling:
   - Loading states with ProgressView
   - Network error messages
   - No results found handling
   - Invalid/empty search term handling
5. Decode JSON response into Swift Codable models
6. Maintain exactly 10 most recent searches (FIFO - remove oldest when limit exceeded)

**UI/UX Requirements:**
1. Clean, modern SwiftUI interface
2. Search field prominently displayed
3. Search history displayed as a scrollable list
4. Results sheet shows cocktail cards with:
   - Cocktail image (using Kingfisher's cached async loading)
   - Cocktail name
   - Any other relevant details from API (instructions, category, glass type, etc.)
5. Loading indicator during API calls
6. Error messages displayed inline with retry option
7. Dismiss button or swipe-to-dismiss for results sheet

</requirements>

<implementation>

**Project Structure:**
Update the existing Example1 project with these components:

1. **Models** (`./Example1/Models/`):
   - `Cocktail.swift` - Codable model matching API response structure
   - `CocktailSearchResponse.swift` - Wrapper for API response array

2. **Services** (`./Example1/Services/`):
   - `CocktailService.swift` - API client with async/await networking
   - Handle URL construction, URLSession calls, JSON decoding
   - Throw descriptive errors for various failure cases

3. **Views** (`./Example1/Views/`):
   - `CocktailSearchView.swift` - Main view with search field and history
   - `CocktailResultsView.swift` - Sheet modal displaying search results
   - `CocktailCardView.swift` - Individual cocktail card component with Kingfisher image
   - `SearchHistoryRow.swift` - History item row component

4. **ViewModels** (`./Example1/ViewModels/`):
   - `CocktailSearchViewModel.swift` - @Observable class managing:
     - Search state (idle, loading, success, error)
     - Current search results
     - Search history (@AppStorage wrapper)
     - Search execution logic
     - History management (add, limit to 10, persist)

**Package Dependencies:**
Add Kingfisher package dependency. Include instructions for adding via Swift Package Manager:
- Repository: https://github.com/onevcat/Kingfisher.git
- Version: Latest stable release

**API Response Structure:**
The API returns JSON like:
```json
{
  "drinks": [
    {
      "idDrink": "11007",
      "strDrink": "Margarita",
      "strCategory": "Ordinary Drink",
      "strInstructions": "Rub the rim...",
      "strDrinkThumb": "https://www.thecocktaildb.com/images/media/drink/...",
      "strGlass": "Cocktail glass",
      ...
    }
  ]
}
```

Decode at minimum: idDrink, strDrink, strCategory, strInstructions, strDrinkThumb, strGlass

**State Management Patterns:**
- Use @State for local view state
- Use @AppStorage for persisting search history array (encode/decode as JSON string)
- Use @Observable macro for ViewModel (Swift 6.2 pattern, not ObservableObject)
- Use async/await with Task for API calls from view actions

**Error Handling Strategy:**
Create a custom enum for error states:
- `.networkError(String)` - Connection issues
- `.decodingError` - JSON parsing failed
- `.noResults` - API returned empty array
- `.invalidSearchTerm` - Empty or whitespace-only input

Display user-friendly messages for each error type with a retry button.

**What to AVOID and WHY:**
- Don't use ObservableObject - Swift 6.2 uses @Observable macro for better performance
- Don't use .tabItem modifier for tabs - Not applicable to this single-view app
- Don't manually implement image caching - Kingfisher handles this efficiently
- Don't use completion handlers - Use async/await for cleaner, safer concurrency
- Don't ignore loading states - Users need feedback during network calls
- Don't store unlimited history - Limit to 10 to prevent unbounded storage growth

</implementation>

<output>

**Create these files:**

1. `./Example1/Models/Cocktail.swift` - Codable cocktail model
2. `./Example1/Models/CocktailSearchResponse.swift` - API response wrapper
3. `./Example1/Services/CocktailService.swift` - Networking service
4. `./Example1/ViewModels/CocktailSearchViewModel.swift` - Business logic and state
5. `./Example1/Views/CocktailSearchView.swift` - Main search interface
6. `./Example1/Views/CocktailResultsView.swift` - Results sheet modal
7. `./Example1/Views/CocktailCardView.swift` - Individual cocktail card
8. `./Example1/Views/SearchHistoryRow.swift` - History list item

**Update this file:**

- `./Example1/ContentView.swift` - Replace with CocktailSearchView or embed it

**Documentation:**

- `./SETUP.md` - Brief instructions for:
  - Adding Kingfisher package dependency via Xcode
  - Running the app
  - Testing with sample searches (margarita, mojito, etc.)

</output>

<verification>

Before declaring complete, verify your implementation:

**Functional Tests:**
1. Enter "margarita" and tap search - results appear in sheet modal
2. Dismiss sheet, enter "mojito" and search - new results appear
3. Check that both searches appear in history list (most recent first)
4. Tap "margarita" in history - automatically re-runs search with results
5. Perform 12 different searches - verify only last 10 remain in history
6. Force quit app and relaunch - verify history persisted
7. Search for nonsense term (e.g., "xyzabc") - verify "no results" message
8. Turn off network and search - verify network error message displays

**Code Quality Checks:**
1. All models conform to Codable and Sendable (Swift 6.2 concurrency safety)
2. ViewModel uses @Observable macro (not ObservableObject)
3. All async operations use proper structured concurrency
4. Images load using Kingfisher's KFImage view
5. No force unwraps (use safe unwrapping patterns)
6. Error cases all handled with user-friendly messages
7. Loading states display ProgressView during network calls

**UI/UX Checks:**
1. Search field is easily accessible and clearly labeled
2. History list is scrollable if more than screen height
3. Results sheet can be dismissed by swipe or button
4. Images load smoothly with Kingfisher caching
5. Error messages are clear and actionable
6. Loading indicators appear during all async operations

</verification>

<success_criteria>

✓ User can enter a cocktail name and see results in a sheet modal
✓ Results include images (loaded via Kingfisher), names, and details
✓ Search history displays last 10 searches on main screen
✓ Tapping history item automatically performs that search
✓ History persists between app launches using @AppStorage
✓ Comprehensive error handling for network, decoding, and edge cases
✓ Loading states provide clear feedback during API calls
✓ Code follows Swift 6.2 and modern SwiftUI best practices
✓ All files created in proper directory structure
✓ Kingfisher package integrated for image caching
✓ App builds and runs without errors
✓ SETUP.md provides clear instructions for running the app

</success_criteria>