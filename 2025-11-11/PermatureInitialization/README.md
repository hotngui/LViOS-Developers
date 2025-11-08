# Project Overview: Premature Initialization Demo

This is a demonstration/testing app that illustrates and tracks SwiftUI view lifecycle behavior, specifically focusing on initialization and task execution patterns in a TabView.

## Key Purpose

The app is designed to investigate and demonstrate when SwiftUI views get initialized and when their `.task` modifiers get called, particularly in the context of a tab-based interface.

## Structure

**Main App:** A simple TabView with three tabs:
1. Home (house icon)
2. Search (magnifying glass icon)
3. Profile (person icon)

## Debugging Features

Each view includes:
- **Global counters** (`<name>ViewInitCallCount` and `<name>ViewTaskCallCount`) that track:
  - How many times each view's `init()` is called
  - How many times each view's `.task` modifier executes
- **Console logging** that prints initialization and task execution counts
- **Loading simulation** - Each tab shows a ProgressView for 2 seconds (simulating async data loading) before displaying the actual content

## The "Premature Initialization" Issue

The app name suggests it's exploring whether SwiftUI initializes all tab views upfront (premature initialization) or only when they're actually displayed. This is a common SwiftUI behavior question since the framework may eagerly initialize views even if they're not immediately visible to the user.

This type of diagnostic app is useful for understanding SwiftUI's performance characteristics and optimizing apps with multiple tabs or complex view hierarchies.
