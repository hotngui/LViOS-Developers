# US State Information App - Implementation Documentation

## Overview

This is a production-ready SwiftUI app for iOS 26+ that allows users to query information about US states using Apple's FoundationModels framework. The app provides comprehensive state information including interactive maps, state capitals, state birds, and state plants, with both text and voice input options.

## Architecture

The app follows the MVVM (Model-View-ViewModel) pattern with clear separation of concerns:

```
Example/
├── Models/
│   └── StateInformation.swift          # Data model with @Generable macro
├── Services/
│   ├── FoundationModelsService.swift   # FoundationModels wrapper with guardrails
│   └── SpeechRecognitionService.swift  # Speech recognition wrapper
├── ViewModels/
│   └── StateQueryViewModel.swift       # Main business logic coordinator
├── Views/
│   ├── StateInputView.swift            # Text and voice input interface
│   ├── StateInformationView.swift      # Display state information
│   └── StateMapView.swift              # MapKit integration
├── ContentView.swift                   # Main coordinator view
├── ExampleApp.swift                    # App entry point
└── Info.plist                          # Privacy permissions
```

## Key Features Implemented

### 1. FoundationModels Integration with Guardrails

**File**: `Services/FoundationModelsService.swift`

- Uses Apple's FoundationModels framework with the `@Generable` macro for type-safe responses
- Implements a two-step validation process:
  1. **Guardrail validation**: Checks if query is about a US state before processing
  2. **Information generation**: Uses guided generation to produce structured StateInformation
- Provides clear error messages when queries are rejected
- Handles all FoundationModels errors gracefully

**Key Implementation**:
```swift
@Generable
struct StateInformation: Sendable {
    var stateName: String
    var capital: String
    var stateBird: String?
    var statePlant: String?
    var centerLatitude: Double
    var centerLongitude: Double
}
```

### 2. Speech Recognition with Permission Handling

**File**: `Services/SpeechRecognitionService.swift`

- Uses iOS Speech framework for voice input
- Requests both microphone and speech recognition permissions
- Provides real-time transcription feedback
- Handles errors with user-friendly messages
- Uses modern Swift concurrency (async/await)

**Permission strings** (in Info.plist):
- `NSSpeechRecognitionUsageDescription`: "We need access to speech recognition to allow you to search for US states using your voice."
- `NSMicrophoneUsageDescription`: "We need access to your microphone to enable voice search for US state information."

### 3. MapKit Integration

**File**: `Views/StateMapView.swift`

- Displays interactive map centered on queried state
- Uses state coordinates from FoundationModels response
- Shows state capital marker
- Supports realistic elevation mapping
- Fully accessible with VoiceOver labels

### 4. State Management with Swift 6.2

**File**: `ViewModels/StateQueryViewModel.swift`

- Uses `@Observable` macro (Swift 6.2 feature) instead of older `@ObservableObject`
- Manages query states: idle, loading, success, error
- Coordinates between FoundationModels and Speech services
- Handles all async operations with proper error handling

### 5. Modern SwiftUI UI/UX

**Files**: `Views/StateInputView.swift`, `Views/StateInformationView.swift`, `ContentView.swift`

- **Latest SwiftUI patterns**: No deprecated modifiers
- **Accessibility**: Full VoiceOver support with proper labels and hints
- **Loading states**: Clear visual feedback during operations
- **Error handling**: User-friendly error messages with retry options
- **Animations**: Smooth transitions between states
- **Dynamic Type**: Supports system font scaling

## User Experience Flow

### Text Input Flow
1. User types state name in search field
2. Taps "Search" button or presses Return
3. Loading indicator appears
4. FoundationModels validates and processes query
5. Results display with map and state information

### Voice Input Flow
1. User taps "Voice" button
2. Permission request (first time only)
3. Visual feedback shows "Listening..." with waveform animation
4. Real-time transcription displays
5. User taps "Stop" or finishes speaking
6. Query automatically submits
7. Results display

### Guardrail Rejection Flow
1. User queries non-state topic (e.g., "What is the capital of France?")
2. Guardrail validation rejects query
3. Clear error message: "I can only provide information about US states. Try asking about a state like 'California' or 'New York'."
4. User can try again with valid state query

## Technical Highlights

### Swift 6.2 Features Used
- `@Observable` macro for state management
- `@Generable` macro for FoundationModels type-safe responses
- Modern concurrency with async/await throughout
- `Sendable` protocol for thread safety
- Latest SwiftUI view modifiers and symbol effects

### Production-Quality Code
- Comprehensive error handling at every layer
- Accessibility labels and hints on all interactive elements
- Loading states for all async operations
- Clean separation of concerns (MVVM)
- Extensive documentation comments
- Type safety throughout

### Accessibility Features
- VoiceOver support for all UI elements
- Semantic accessibility labels
- Accessibility hints for guidance
- Support for Dynamic Type
- Color contrast considerations

## Error Handling Strategy

The app handles errors at multiple levels:

1. **Input validation**: Empty queries rejected at UI level
2. **Guardrail validation**: Non-state queries blocked before processing
3. **Service errors**: FoundationModels and Speech errors caught and displayed
4. **Network errors**: Graceful handling with retry options
5. **Missing data**: Optional state bird/plant handled without errors

## Configuration Requirements

### Info.plist Permissions
The app requires two privacy permission strings:
- `NSSpeechRecognitionUsageDescription`
- `NSMicrophoneUsageDescription`

### iOS Version
- Minimum: iOS 26.0
- Target: iOS 26.0+

### Frameworks Required
- SwiftUI
- FoundationModels
- Speech
- AVFoundation
- MapKit

## Testing Recommendations

### Test Cases
1. **Valid state queries**:
   - "California" → Should show map, capital (Sacramento), bird, plant
   - "Texas" → Complete information
   - "Delaware" → Smaller state test

2. **Guardrail tests**:
   - "What is the capital of France?" → Should reject
   - "Tell me about Canada" → Should reject
   - "Paris" → Should reject (city, not state)

3. **Voice input**:
   - Grant permissions → Should work
   - Deny permissions → Should show error with Settings guidance
   - Background noise → Speech recognition handles gracefully

4. **Edge cases**:
   - Empty input → Validation error
   - Network failure → Retry option
   - Missing state plant data → Shows "Information not available"

### Accessibility Testing
- Enable VoiceOver and test full navigation
- Test with different Dynamic Type sizes
- Verify all interactive elements have labels

## Known Limitations

1. **State boundaries**: The current implementation shows a marker at the state center but doesn't draw full state boundary polygons (would require additional GeoJSON data)
2. **Offline mode**: Requires internet connection for FoundationModels queries
3. **iOS 26+ only**: Uses FoundationModels framework not available on earlier iOS versions

## Future Enhancements

Potential improvements for future versions:
- State boundary polygon rendering
- Caching of previously queried states
- Quiz mode for educational purposes
- State comparison feature
- Historical information about states
- State flag imagery
- Population and area statistics

## Build Instructions

1. Open `Example.xcodeproj` in Xcode 26+
2. Ensure Info.plist is added to the target
3. Select iOS 26+ simulator or device
4. Build and run (Cmd+R)

## Code Quality

All code follows:
- Swift 6.2 best practices
- CLAUDE.md guidelines for Swift and SwiftUI
- Latest SwiftUI patterns (no deprecated APIs)
- Comprehensive error handling
- Production-ready standards

## Sources and Documentation

This implementation was built following Apple's official documentation and best practices:

- [Foundation Models Framework - Apple Developer](https://developer.apple.com/documentation/foundationmodels)
- [Meet the Foundation Models framework - WWDC25](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Exploring the Foundation Models framework](https://www.createwithswift.com/exploring-the-foundation-models-framework/)
- [Speech Framework - Apple Developer](https://developer.apple.com/documentation/speech)
- [Asking Permission to Use Speech Recognition](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition)

---

**Created**: December 14, 2025
**Swift Version**: 6.2
**iOS Target**: 26.0+
**Architecture**: MVVM with SwiftUI
