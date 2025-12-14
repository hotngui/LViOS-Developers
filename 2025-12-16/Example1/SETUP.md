# Cocktail Search App - Setup Instructions

A SwiftUI application that searches for cocktails using TheCocktailDB API, displays results with images, and maintains searchable history.

## Prerequisites

- Xcode 16.0 or later
- iOS 17.0 or later
- Swift 6.2

## Setup Steps

### 1. Add Kingfisher Package Dependency

The app uses Kingfisher for efficient image loading and caching.

1. Open `Example1.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "Example1" target
4. Click on the "Package Dependencies" tab
5. Click the "+" button to add a package
6. Enter the repository URL: `https://github.com/onevcat/Kingfisher.git`
7. Select "Up to Next Major Version" with version `8.0.0` (or latest)
8. Click "Add Package"
9. Ensure "Kingfisher" is added to the "Example1" target
10. Click "Add Package" to confirm

### 2. Add Files to Xcode Project

All files have been created in the proper directory structure. You need to add them to the Xcode project:

1. In Xcode, right-click on the "Example1" group in the navigator
2. Select "Add Files to Example1..."
3. Navigate to and select the following folders:
   - `Models` folder
   - `Services` folder
   - `ViewModels` folder
   - `Views` folder
4. Ensure "Copy items if needed" is **unchecked** (files are already in the correct location)
5. Ensure "Create groups" is selected
6. Ensure the "Example1" target is checked
7. Click "Add"

### 3. Build and Run

1. Select a simulator or device (iOS 17.0+)
2. Press `Cmd+R` to build and run the app

## Testing the App

### Basic Search Test

1. Enter "margarita" in the search field
2. Tap the "Search" button or press return
3. Results should appear in a sheet modal with images
4. Tap "Done" to dismiss the sheet

### Search History Test

1. Perform multiple searches (e.g., "mojito", "daiquiri", "martini")
2. Each search should appear in the "Recent Searches" list
3. Tap any history item - it should automatically re-run that search
4. The most recent search should appear at the top

### Persistence Test

1. Perform several searches
2. Force quit the app (swipe up from app switcher)
3. Relaunch the app
4. Search history should be preserved

### History Limit Test

1. Perform 12 different searches
2. Verify only the last 10 searches remain in the history
3. Oldest searches should be removed automatically

### Error Handling Tests

**No Results Test:**
1. Search for a nonsense term (e.g., "xyzabc123")
2. Should display: "No cocktails found. Try a different search term."
3. Retry button should allow another attempt

**Empty Search Test:**
1. Leave search field empty and try to search
2. Search button should be disabled
3. Or display: "Please enter a valid search term."

**Network Error Test:**
1. Turn off WiFi and cellular data
2. Perform a search
3. Should display: "Network error: [error details]"
4. Turn network back on and use retry button

## Sample Search Terms

Try these popular cocktails:
- margarita
- mojito
- martini
- old fashioned
- manhattan
- daiquiri
- cosmopolitan
- whiskey sour
- mai tai
- negroni

## Features

- **Search by Name**: Enter cocktail names to find recipes
- **Visual Results**: High-quality images loaded with Kingfisher caching
- **Search History**: Last 10 searches preserved between launches
- **Quick Re-search**: Tap any history item to re-run that search
- **Error Handling**: Clear messages for network errors, no results, etc.
- **Loading States**: Progress indicators during API calls
- **Modern SwiftUI**: Built with Swift 6.2 and latest SwiftUI patterns

## Architecture

- **Models**: Codable structs for API response decoding
- **Services**: Actor-based API client with async/await
- **ViewModels**: @Observable ViewModel with state management
- **Views**: Modular SwiftUI components with sheet presentation
- **Storage**: @AppStorage equivalent using UserDefaults for history persistence

## API Information

- **API**: TheCocktailDB (free tier)
- **Endpoint**: `https://www.thecocktaildb.com/api/json/v1/1/search.php?s={searchTerm}`
- **Response**: JSON with array of cocktail objects
- **Rate Limit**: Free tier has reasonable limits for testing

## Troubleshooting

### Build Errors

If you encounter build errors:
1. Clean build folder: `Cmd+Shift+K`
2. Delete derived data: `Cmd+Option+Shift+K`
3. Ensure Kingfisher package is properly added
4. Verify all files are added to the Example1 target

### Runtime Errors

If the app crashes or doesn't work:
1. Check console for error messages
2. Verify network connection is active
3. Ensure iOS deployment target is 17.0+
4. Check that all files are properly imported

### Kingfisher Issues

If images don't load:
1. Verify Kingfisher package is installed
2. Check import statements in CocktailCardView.swift
3. Ensure API returns valid image URLs
4. Check network permissions in Info.plist

## Project Structure

```
Example1/
├── Models/
│   ├── Cocktail.swift
│   └── CocktailSearchResponse.swift
├── Services/
│   └── CocktailService.swift
├── ViewModels/
│   └── CocktailSearchViewModel.swift
├── Views/
│   ├── CocktailSearchView.swift
│   ├── CocktailResultsView.swift
│   ├── CocktailCardView.swift
│   └── SearchHistoryRow.swift
├── ContentView.swift
└── Example1App.swift
```

## License

Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
