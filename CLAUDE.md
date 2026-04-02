# Roundeo Claude Code Guidelines

## Project Overview
Roundeo is a macOS video editor for adding rounded corners, device frames, and cropping to videos with transparent output. Built in Swift/SwiftUI.

## Code Organization

### Views
- One view struct per file, named `*View.swift`
- Private views should be extracted to separate files, not nested
- All views receive `@ObservedObject var viewModel: VideoViewModel` by parameter
- No separate view models — logic lives in the single `VideoViewModel`

### Geometry & Layout
- Extract layout calculations to separate utility structs (e.g., `VideoPreviewGeometry`)
- Geometry helpers should be value types (structs) with computed properties
- Named constants belong next to the code that owns them, not in a global constants file
- Keep views focused on rendering, not on math

### File Structure
```
Roundeo/
├── RoundeoApp.swift              # App entry point
├── ContentView.swift             # Root container
├── VideoViewModel.swift          # Single source of state
├── VideoPreviewView.swift        # Main canvas orchestrator (simplified)
├── VideoPreviewGeometry.swift    # Layout calculations
├── CheckerboardView.swift        # UI components
├── DropZoneView.swift
├── RoundedVideoLayerView.swift
├── OverlayLayerView.swift
├── CropOverlayView.swift
├── PlayerControlsView.swift
├── HelpView.swift
├── OnboardingView.swift
└── SettingsView.swift
```

## Git Workflow
- Use `git pull --rebase` instead of merging
- Commit messages should be descriptive ("Refactor", "Fix", "Add" not just "Update")
- Always pull before pushing to avoid rebase conflicts

## Code Patterns

### ObservedObject Pattern
All views that modify state use:
```swift
@ObservedObject var viewModel: VideoViewModel
```
Not `@EnvironmentObject` — it's explicitly passed as a parameter.

### No Duplicates
Don't create private copies of views/helpers that already exist elsewhere. Extract to separate files instead.

### Gesture Handling
- Overlay dragging and resizing use `@State` for drag tracking
- Snap thresholds should be named constants (e.g., `snapThreshold: CGFloat = 8`)
- Always guard against `scale > 0` before math operations

## Before Committing
- Verify the project builds (Swift compiler should be clean)
- Test core flows: load video → adjust corners → crop → add frame → export
- Check that VideoPreviewView remains focused (no raw geometry math)

## Things to Avoid
- Don't add `VideoViewModel` imports in view files — it should be in scope from ContentView
- Don't inline geometry calculations in views — extract to geometry helper
- Don't create nested private views — use separate files
- Don't use force unwrap (`!`) except where guaranteed by SwiftUI (e.g., `viewModel.player!` when it's non-nil)
