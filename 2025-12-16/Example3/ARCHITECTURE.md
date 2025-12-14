# Architecture Documentation - US State Information App

## System Architecture Overview

This document provides a comprehensive view of the app's architecture using UML diagrams.

## Class Diagram

```mermaid
classDiagram
    class ContentView {
        -StateQueryViewModel viewModel
        +body: View
        -idleStateView: View
        -loadingView: View
        -errorView: View
    }

    class StateQueryViewModel {
        +QueryState queryState
        +String searchText
        +String? errorMessage
        +Bool showError
        -FoundationModelsService foundationModelsService
        +SpeechRecognitionService speechRecognitionService
        +performQuery(String) async
        +startVoiceInput() async
        +stopVoiceInput() async
        +reset()
        +retry() async
    }

    class FoundationModelsService {
        -SystemLanguageModel model
        -LanguageModelSession? session
        +queryStateInformation(String) async throws StateInformation
        -validateStateQuery(String) async throws Bool
    }

    class SpeechRecognitionService {
        +Bool isRecording
        +String recognizedText
        -SFSpeechRecognizer speechRecognizer
        -AVAudioEngine audioEngine
        +requestPermissions() async Bool
        +startRecording() throws
        +stopRecording()
    }

    class StateInformation {
        +String stateName
        +String capital
        +String? stateBird
        +String? statePlant
        +Double centerLatitude
        +Double centerLongitude
    }

    class QueryState {
        <<enumeration>>
        idle
        loading
        success(StateInformation)
        error(String)
    }

    class StateInputView {
        +StateQueryViewModel viewModel
        +body: View
        -performSearch()
    }

    class StateInformationView {
        +StateInformation stateInfo
        +body: View
    }

    class StateMapView {
        +StateInformation stateInfo
        -MapCameraPosition position
        +body: View
    }

    ContentView --> StateQueryViewModel
    ContentView --> StateInputView
    ContentView --> StateInformationView
    StateQueryViewModel --> FoundationModelsService
    StateQueryViewModel --> SpeechRecognitionService
    StateQueryViewModel --> QueryState
    StateInformationView --> StateMapView
    StateInformationView --> StateInformation
    StateMapView --> StateInformation
    FoundationModelsService ..> StateInformation : creates
    QueryState --> StateInformation : contains
```

## Sequence Diagram - Text Query Flow

```mermaid
sequenceDiagram
    actor User
    participant UI as StateInputView
    participant VM as StateQueryViewModel
    participant FMS as FoundationModelsService
    participant FM as FoundationModels API
    participant CV as ContentView

    User->>UI: Types "California"
    User->>UI: Taps Search
    UI->>VM: performQuery("California")
    VM->>VM: Set queryState = .loading
    VM->>CV: Update UI (show loading)
    CV->>User: Display loading spinner

    VM->>FMS: queryStateInformation("California")
    FMS->>FM: validateStateQuery()
    FM-->>FMS: true (valid state)

    FMS->>FM: generate(prompt, of: StateInformation.self)
    FM-->>FMS: StateInformation object
    FMS-->>VM: Return StateInformation

    VM->>VM: Set queryState = .success(stateInfo)
    VM->>CV: Update UI
    CV->>User: Display state information with map
```

## Sequence Diagram - Voice Query Flow

```mermaid
sequenceDiagram
    actor User
    participant UI as StateInputView
    participant VM as StateQueryViewModel
    participant SRS as SpeechRecognitionService
    participant SF as Speech Framework
    participant FMS as FoundationModelsService
    participant CV as ContentView

    User->>UI: Taps Voice button
    UI->>VM: startVoiceInput()
    VM->>SRS: requestPermissions()
    SRS->>SF: Request microphone & speech permissions
    SF-->>SRS: Permissions granted
    SRS-->>VM: true

    VM->>SRS: startRecording()
    SRS->>SF: Start audio engine & recognition
    SRS->>UI: Update isRecording = true
    UI->>User: Show "Listening..." with waveform

    User->>SF: Speaks "Texas"
    SF->>SRS: Real-time transcription
    SRS->>UI: Update recognizedText
    UI->>User: Display "Texas"

    User->>UI: Taps Stop
    UI->>VM: stopVoiceInput()
    VM->>SRS: stopRecording()
    SRS->>SF: Stop audio engine

    VM->>FMS: queryStateInformation("Texas")
    Note over VM,FMS: Same flow as text query
    FMS-->>VM: StateInformation
    VM->>CV: Update with results
    CV->>User: Display state information
```

## Sequence Diagram - Guardrail Rejection Flow

```mermaid
sequenceDiagram
    actor User
    participant UI as StateInputView
    participant VM as StateQueryViewModel
    participant FMS as FoundationModelsService
    participant FM as FoundationModels API
    participant CV as ContentView

    User->>UI: Types "What is the capital of France?"
    User->>UI: Taps Search
    UI->>VM: performQuery("What is the capital of France?")
    VM->>VM: Set queryState = .loading

    VM->>FMS: queryStateInformation(query)
    FMS->>FM: validateStateQuery(query)

    Note over FM: Validation session checks<br/>if query is about US state
    FM-->>FMS: false (not a US state)

    FMS-->>VM: throw ServiceError.invalidQuery
    VM->>VM: Set queryState = .error
    VM->>VM: Set errorMessage
    VM->>VM: Set showError = true

    VM->>CV: Update UI
    CV->>User: Show error alert with message:<br/>"I can only provide information<br/>about US states..."

    User->>CV: Taps OK
    CV->>VM: showError = false
    VM->>CV: Dismiss alert
```

## Component Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        CV[ContentView]
        SIV[StateInputView]
        SINV[StateInformationView]
        SMV[StateMapView]
    end

    subgraph "Business Logic Layer"
        SQVM[StateQueryViewModel]
    end

    subgraph "Service Layer"
        FMS[FoundationModelsService]
        SRS[SpeechRecognitionService]
    end

    subgraph "Data Layer"
        SI[StateInformation Model]
        QS[QueryState Enum]
    end

    subgraph "iOS Frameworks"
        FM[FoundationModels]
        SF[Speech Framework]
        AVF[AVFoundation]
        MK[MapKit]
    end

    CV --> SQVM
    CV --> SIV
    CV --> SINV
    SINV --> SMV

    SQVM --> FMS
    SQVM --> SRS
    SQVM --> QS

    FMS --> FM
    FMS --> SI

    SRS --> SF
    SRS --> AVF

    SMV --> MK
    SMV --> SI

    QS --> SI

    style CV fill:#e1f5ff
    style SQVM fill:#fff4e1
    style FMS fill:#ffe1f5
    style SRS fill:#ffe1f5
```

## State Machine - Query State Flow

```mermaid
stateDiagram-v2
    [*] --> Idle: App Launch

    Idle --> Loading: User submits query

    Loading --> Success: Valid state query processed
    Loading --> Error: Guardrail rejection or error

    Success --> Idle: User resets or new query
    Error --> Idle: User taps "Try Again"
    Error --> Loading: User taps "Retry"

    Success --> Loading: User submits new query

    note right of Idle
        Empty state
        Input ready
    end note

    note right of Loading
        Progress indicator
        Processing query
    end note

    note right of Success
        Display map
        Show state info
    end note

    note right of Error
        Error message
        Retry option
    end note
```

## Data Flow Architecture

```mermaid
flowchart LR
    subgraph Input
        A[User Text Input]
        B[User Voice Input]
    end

    subgraph Processing
        C[StateQueryViewModel]
        D{Query Type?}
        E[Text Query]
        F[Speech Recognition]
    end

    subgraph Validation
        G[FoundationModelsService]
        H{Guardrail Check}
        I[Valid State Query]
        J[Invalid Query]
    end

    subgraph Generation
        K[FoundationModels API]
        L[@Generable Response]
        M[StateInformation]
    end

    subgraph Display
        N[ContentView]
        O[StateInformationView]
        P[StateMapView]
    end

    A --> C
    B --> F
    F --> C
    C --> D
    D --> E
    D --> F
    E --> G
    F --> G

    G --> H
    H -->|Yes| I
    H -->|No| J

    I --> K
    K --> L
    L --> M

    J --> N
    M --> N
    N --> O
    O --> P

    style H fill:#ffcccc
    style I fill:#ccffcc
    style J fill:#ffcccc
    style M fill:#ccccff
```

## Error Handling Flow

```mermaid
flowchart TD
    A[User Query] --> B{Input Validation}
    B -->|Empty| C[Show Input Error]
    B -->|Valid| D[Start Processing]

    D --> E{Guardrail Check}
    E -->|Not US State| F[ServiceError.invalidQuery]
    E -->|Valid State| G[Generate Information]

    G --> H{Generation Success?}
    H -->|No| I[ServiceError.generationFailed]
    H -->|Yes| J[Return StateInformation]

    F --> K[Display Error Alert]
    I --> K
    C --> K

    K --> L{User Action}
    L -->|Retry| A
    L -->|Try Again| M[Reset to Idle]
    L -->|OK| M

    J --> N[Display Success]

    style F fill:#ffcccc
    style I fill:#ffcccc
    style C fill:#ffcccc
    style J fill:#ccffcc
    style N fill:#ccffcc
```

## Key Design Patterns

### 1. MVVM Pattern
- **Model**: `StateInformation` - Pure data structure
- **View**: SwiftUI views (ContentView, StateInputView, etc.)
- **ViewModel**: `StateQueryViewModel` - Business logic and state management

### 2. Service Layer Pattern
- `FoundationModelsService` - Encapsulates AI logic
- `SpeechRecognitionService` - Encapsulates speech recognition
- Clean separation from ViewModels

### 3. Strategy Pattern
- Query validation strategy (guardrails)
- Different input strategies (text vs. voice)

### 4. Observer Pattern
- SwiftUI's `@Observable` macro for reactive updates
- Automatic UI updates on state changes

### 5. Dependency Injection
- Services injected into ViewModel
- Easy to test and mock

## Concurrency Model

```mermaid
flowchart TB
    subgraph "Main Thread (MainActor)"
        A[UI Updates]
        B[StateQueryViewModel]
        C[SpeechRecognitionService]
    end

    subgraph "Background Tasks"
        D[FoundationModels API Calls]
        E[Speech Recognition Processing]
    end

    B -->|async/await| D
    C -->|async/await| E

    D -->|Return to MainActor| B
    E -->|Return to MainActor| C

    B --> A
    C --> A

    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#fff4e1
    style D fill:#e1ffe1
    style E fill:#e1ffe1
```

All async operations use Swift 6.2 modern concurrency:
- `async/await` for asynchronous calls
- `@MainActor` for UI updates
- `Sendable` for thread-safe data passing

## Security & Privacy

```mermaid
flowchart LR
    A[User Input] --> B{Permission Check}
    B -->|Speech/Mic| C[Request Permission]
    C --> D{Granted?}
    D -->|No| E[Show Error]
    D -->|Yes| F[Process Input]

    F --> G[Local Processing]
    G --> H{FoundationModels Query}
    H --> I[On-Device LLM]

    I --> J[Guardrail Validation]
    J --> K{Valid?}
    K -->|No| L[Reject Query]
    K -->|Yes| M[Generate Response]

    style C fill:#ffffcc
    style J fill:#ffcccc
    style I fill:#ccffcc
```

Privacy considerations:
- All permissions requested with clear explanations
- On-device FoundationModels processing
- No data sent to external servers
- User controls all data

---

## Summary

This architecture provides:
- **Separation of concerns** through MVVM
- **Type safety** with Swift 6.2 features
- **Testability** through service layer abstraction
- **Scalability** with clear component boundaries
- **Maintainability** through clean code organization
- **Production quality** with comprehensive error handling
