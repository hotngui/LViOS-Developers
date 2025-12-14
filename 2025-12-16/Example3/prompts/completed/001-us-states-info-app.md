<objective>
Build a production-ready SwiftUI app that allows users to query information about US states using Apple's FoundationModels framework. The app should provide comprehensive state information including a highlighted map view, state capital, state bird, and state plant. Implement robust guardrails to limit queries strictly to US states, with both text and voice input options, and production-quality error handling and accessibility support.

This app will serve as a reference tool for users wanting to learn about US states through an intuitive, AI-powered interface.
</objective>

<context>
You are working with an existing SwiftUI app project targeting iOS 26+ with Swift 6.2. The project has a basic structure with ExampleApp.swift and ContentView.swift that need to be transformed into a fully-featured states information app.

Read the CLAUDE.md file for Swift and SwiftUI coding guidelines, which emphasize using the latest Swift 6.2 features and modern SwiftUI patterns.

The app must integrate Apple's FoundationModels framework for natural language processing and information generation about US states.
</context>

<requirements>
## Core Functionality
1. **Dual Input Methods**: Support both text field input and voice input using iOS speech recognition
2. **FoundationModels Integration**: Use Apple's FoundationModels framework to process queries and generate state information
3. **Guardrails Implementation**: Configure FoundationModels guardrails to strictly reject non-state queries and provide clear error messages
4. **MapKit Integration**: Display an interactive map centered on the queried state with visual highlighting of state boundaries
5. **State Information Display**: Show state capital, state bird, and state plant (when available)
6. **Production-Ready Quality**: Comprehensive error handling, loading states, accessibility support, and polished animations

## Information to Display
For each valid state query, present:
- Interactive map with state highlighting using MapKit
- State name (official)
- State capital city
- State bird (official state bird)
- State plant/flower (official state flower or plant)
- Handle cases where state bird or plant information may not be available

## User Experience Requirements
- Loading indicators during FoundationModels processing
- Clear error messages when:
  - Queries are not about US states (blocked by guardrails)
  - Network or API failures occur
  - Speech recognition fails
- Empty state when no query has been made yet
- Smooth animations between states
- VoiceOver accessibility support
- Dynamic Type support for text sizing
</requirements>

<implementation>
## Architecture Approach
1. **MVVM Pattern**: Use ViewModel to manage state, FoundationModels interactions, and business logic
2. **Modern Concurrency**: Use Swift 6.2 async/await for all asynchronous operations
3. **SwiftUI Best Practices**: Use latest SwiftUI views and modifiers (avoid deprecated patterns)

## FoundationModels Setup
- Configure the FoundationModels framework with appropriate initialization
- Set up guardrails specifically to detect and reject queries that are not about US states
- The guardrail should check if the query is asking about one of the 50 US states
- Return clear, user-friendly error messages when guardrails are triggered
- Handle FoundationModels errors gracefully with appropriate user feedback

WHY: Guardrails are critical because they prevent the model from answering off-topic queries and ensure the app stays focused on its core purpose. This improves user trust and prevents misuse.

## MapKit Implementation
- Use MapKit's Map view with appropriate region centering on the state
- Implement state boundary highlighting (you may need to use MKPolygon or similar for state shapes)
- Consider using geocoding to get coordinates from state names
- Handle map loading states and errors

WHY: The map provides crucial visual context and makes the information more engaging and memorable for users. It transforms abstract state information into concrete geographic understanding.

## Speech Recognition
- Use iOS Speech framework for voice input
- Request microphone permissions appropriately with clear explanations
- Provide visual feedback during voice recording
- Handle speech recognition errors with helpful recovery messages
- Ensure the microphone button is clearly labeled for accessibility

WHY: Voice input makes the app more accessible and provides a natural, hands-free interaction method that aligns with modern iOS user expectations.

## Error Handling Patterns
- Network errors: Provide retry options with clear messaging
- Guardrail rejections: Explain that only US state queries are supported and provide an example
- Speech recognition failures: Offer fallback to text input
- Missing data (e.g., no state plant): Handle gracefully in UI without showing errors
- Loading timeouts: Set reasonable timeouts and provide feedback

## What to Avoid and Why
- DO NOT use deprecated SwiftUI modifiers like `.tabItem` - use latest SwiftUI patterns as specified in CLAUDE.md
- DO NOT hard-code state information - rely on FoundationModels to generate accurate, up-to-date information
- DO NOT skip loading states - users need feedback during async operations or they'll think the app is frozen
- DO NOT ignore accessibility - VoiceOver users should be able to fully interact with the app
- DO NOT use force unwrapping (!) except in guaranteed-safe scenarios - Swift 6.2 emphasizes safety

WHY: These constraints ensure the app follows modern iOS development best practices, provides excellent UX, and maintains long-term code quality.

## Project Structure
Organize code into logical files:
- `./Example/Views/` - SwiftUI views
- `./Example/ViewModels/` - View models for business logic
- `./Example/Models/` - Data models
- `./Example/Services/` - FoundationModels and MapKit service wrappers
- Update `./Example/ContentView.swift` as the main entry point
- Keep `./Example/ExampleApp.swift` minimal

WHY: Clear separation of concerns makes the codebase maintainable and testable, which is critical for production apps.
</implementation>

<research>
Before implementing, research the following:
1. Check Apple's FoundationModels framework documentation for:
   - Proper initialization and configuration
   - Guardrails API and how to set constraints
   - Best practices for error handling
   - Required entitlements or capabilities
2. Verify iOS 26+ availability of FoundationModels features
3. Review MapKit capabilities for state boundary rendering
4. Check Speech framework requirements for iOS 26+

Use web search if needed to find the latest Apple documentation for these frameworks.
</research>

<output>
Create the following files with relative paths from the project root:

1. `./Example/Services/FoundationModelsService.swift` - Service wrapper for FoundationModels with guardrails configuration
2. `./Example/Services/SpeechRecognitionService.swift` - Speech recognition wrapper
3. `./Example/Models/StateInformation.swift` - Model for state data
4. `./Example/ViewModels/StateQueryViewModel.swift` - Main view model
5. `./Example/Views/StateInputView.swift` - Text and voice input interface
6. `./Example/Views/StateInformationView.swift` - Display state information
7. `./Example/Views/StateMapView.swift` - MapKit integration
8. `./Example/ContentView.swift` - Update as main coordinator view
9. Update project configuration if needed for permissions (Info.plist for microphone, location if needed)

Each file should include:
- Clear documentation comments
- Proper error handling
- Accessibility labels
- Swift 6.2 features where applicable
</output>

<verification>
Before declaring the implementation complete, verify:

1. **Build Success**: The project builds without errors or warnings on iOS 26+ simulator
2. **Text Input**: Can type a state name (e.g., "California") and receive information
3. **Voice Input**: Microphone button triggers speech recognition and processes spoken state names
4. **Guardrails**: Non-state queries (e.g., "What is the weather?") are blocked with clear error messages
5. **Map Display**: MapKit shows the queried state with visual highlighting
6. **Information Accuracy**: State capital, bird, and plant are displayed correctly
7. **Loading States**: Loading indicators appear during processing
8. **Error Handling**: Network errors, speech failures, and guardrail blocks all show appropriate user feedback
9. **Accessibility**: VoiceOver can navigate all UI elements with meaningful labels
10. **No History**: App doesn't persist or show previous queries (as specified)

Test with at least 3 different states including edge cases:
- A well-known state (e.g., "Texas")
- A smaller state (e.g., "Delaware")
- A non-state query to verify guardrails (e.g., "Canada")
</verification>

<success_criteria>
The app is complete when:
- ✅ Users can query US states via text or voice input
- ✅ FoundationModels generates accurate state information with functioning guardrails
- ✅ Maps display with state highlighting using MapKit
- ✅ All required information (capital, bird, plant) is shown when available
- ✅ Production-quality error handling and loading states are implemented
- ✅ VoiceOver and Dynamic Type accessibility work correctly
- ✅ Non-state queries are blocked with helpful error messages
- ✅ Code follows CLAUDE.md Swift 6.2 and SwiftUI guidelines
- ✅ All verification tests pass successfully
</success_criteria>

<examples>
## Example User Flow 1: Successful Text Query
1. User opens app → sees empty state with text field and microphone button
2. User types "California" and taps search
3. Loading indicator appears
4. Map animates to California with highlighted boundaries
5. Information displays:
   - State: California
   - Capital: Sacramento
   - State Bird: California Valley Quail
   - State Plant: California Poppy

## Example User Flow 2: Voice Query
1. User taps microphone button
2. Permission prompt appears (first time) → user grants access
3. Microphone activates with visual feedback
4. User says "Tell me about Texas"
5. Speech converts to text, query processes
6. Results display with Texas map and information

## Example User Flow 3: Guardrail Rejection
1. User types "What is the capital of France?"
2. Loading indicator appears briefly
3. Error message displays: "I can only provide information about US states. Try asking about a state like 'California' or 'New York'."
4. User can try again with valid state query

## Example Error Handling
- **Missing state plant**: Show "State Plant: Information not available" instead of crashing
- **Network error**: "Unable to connect. Please check your internet connection and try again." with retry button
- **Speech recognition failure**: "Couldn't understand. Please try again or use text input."
</examples>