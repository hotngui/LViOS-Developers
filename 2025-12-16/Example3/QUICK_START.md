# Quick Start Guide - US State Information App

## What This App Does

This SwiftUI app lets you explore information about US states using:
- **Text input**: Type a state name
- **Voice input**: Speak your query
- **AI-powered**: Uses Apple's FoundationModels framework
- **Visual maps**: See each state on an interactive map
- **Comprehensive info**: State capital, bird, and plant

## Project Files Overview

### Core App Files
- `/Example/ExampleApp.swift` - App entry point
- `/Example/ContentView.swift` - Main coordinator view with state management
- `/Example/Info.plist` - Privacy permissions for microphone and speech

### Models
- `/Example/Models/StateInformation.swift` - Data structure using @Generable macro

### Services
- `/Example/Services/FoundationModelsService.swift` - AI service with guardrails
- `/Example/Services/SpeechRecognitionService.swift` - Voice recognition service

### ViewModels
- `/Example/ViewModels/StateQueryViewModel.swift` - Business logic coordinator

### Views
- `/Example/Views/StateInputView.swift` - Text and voice input interface
- `/Example/Views/StateInformationView.swift` - Display state information
- `/Example/Views/StateMapView.swift` - Interactive MapKit view

## How to Run

1. **Prerequisites**:
   - Xcode 26 or later
   - macOS running Tahoe or later
   - iOS 26+ simulator or device

2. **Open the project**:
   ```bash
   cd "/Users/joeyjarosz/Experiments/Meta Prompting/Example3"
   open Example.xcodeproj
   ```

3. **Add Info.plist to target** (if needed):
   - Select `Example/Info.plist` in Project Navigator
   - In File Inspector, ensure it's added to the "Example" target

4. **Build and run**:
   - Press `Cmd+R` or click the Run button
   - Select an iOS 26+ simulator or device

## How to Use the App

### Text Search
1. Type a state name (e.g., "California", "Texas", "New York")
2. Press Return or tap the "Search" button
3. View results with map and information

### Voice Search
1. Tap the "Voice" button
2. Grant microphone permission when prompted (first time only)
3. Speak your query (e.g., "Tell me about Texas")
4. Tap "Stop" when finished
5. Results appear automatically

### Features in Action

**Try these queries**:
- "California" - See full state information
- "What's the capital of Florida?" - Natural language works
- "Tell me about Alaska" - Works with voice or text

**Guardrails in action** (will be rejected):
- "What is the capital of France?" - Not a US state
- "Tell me about Canada" - Country, not state
- "Weather in Seattle" - Off-topic query

## Key Features

### Guardrails System
The app uses a two-step validation:
1. First checks if query is about a US state
2. Only processes valid state queries
3. Provides helpful error messages for invalid queries

### Error Handling
- Clear error messages for all failure cases
- Retry options for recoverable errors
- Graceful handling of missing data (e.g., no state plant info)

### Accessibility
- Full VoiceOver support
- Dynamic Type for text scaling
- Semantic labels on all interactive elements
- Keyboard navigation support

## Architecture Pattern

The app uses **MVVM (Model-View-ViewModel)**:

```
┌─────────────────┐
│  ContentView    │ ← Main coordinator
└────────┬────────┘
         │
         ├─→ StateInputView (text/voice input)
         ├─→ StateInformationView (results display)
         └─→ StateMapView (interactive map)
              │
              ├─→ StateQueryViewModel (business logic)
                   │
                   ├─→ FoundationModelsService (AI queries)
                   └─→ SpeechRecognitionService (voice input)
```

## Swift 6.2 Features Used

- **@Observable** macro for reactive state management
- **@Generable** macro for type-safe AI responses
- **async/await** for all asynchronous operations
- **Sendable** protocol for thread safety
- Latest SwiftUI view modifiers and symbol effects

## Troubleshooting

### Build Errors
- Ensure you're using Xcode 26+ and macOS Tahoe+
- Check that Info.plist is added to the target
- Verify iOS deployment target is set to 26.0+

### Runtime Issues
- **"Model unavailable"**: Ensure running on iOS 26+ device/simulator
- **Microphone permission denied**: Check Settings → Privacy → Microphone
- **No results**: Check internet connection (FoundationModels requires connectivity)

### Common Issues
- **Empty state plant**: Some states don't have official plants - this is normal
- **Map not centered**: Coordinates are approximate state centers
- **Voice not working**: Grant microphone permissions in Settings

## Next Steps

To customize the app:
1. **Modify the prompt**: Edit `FoundationModelsService.swift` instructions
2. **Add more info**: Extend `StateInformation` model with additional fields
3. **Customize UI**: Update views in `/Example/Views/` directory
4. **Add features**: See IMPLEMENTATION.md for enhancement ideas

## Testing Checklist

Before deploying:
- [ ] Test text input with 3+ different states
- [ ] Test voice input with microphone permissions
- [ ] Test guardrail rejection with non-state queries
- [ ] Test error handling (airplane mode for network errors)
- [ ] Test accessibility with VoiceOver enabled
- [ ] Test on different device sizes
- [ ] Test with different Dynamic Type sizes

## Resources

- **Full documentation**: See `IMPLEMENTATION.md`
- **Apple FoundationModels**: https://developer.apple.com/documentation/foundationmodels
- **WWDC 2025 Video**: https://developer.apple.com/videos/play/wwdc2025/286/

---

**Questions or Issues?**
Refer to the comprehensive `IMPLEMENTATION.md` file for detailed technical information.
