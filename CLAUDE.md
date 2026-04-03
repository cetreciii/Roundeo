# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roundeo is a macOS SwiftUI app that adds rounded corners to videos, crops them, and exports with true transparency (HEVC alpha `.mov`). It supports drag-and-drop video loading, interactive crop with draggable handles, adjustable corner radius, and PNG overlay (device frames).

- **Platform:** macOS 14.0+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Build:** Open `Roundeo.xcodeproj` in Xcode, then `Cmd+R` to build and run. There is no SPM, CocoaPods, or other dependency manager — no external dependencies.

## Build Commands

```bash
# Build from command line
xcodebuild -project Roundeo.xcodeproj -scheme Roundeo build

# Build and run (Xcode)
# Cmd+R in Xcode
```

There are no tests or linting configured in this project.

## Architecture

**Single-ViewModel MVVM pattern.** The entire app state flows through one `VideoViewModel` (ObservableObject, @MainActor) owned by `ContentView`.

### Key layers

- **`RoundeoApp.swift`** — App entry point. Single `WindowGroup` scene with a `Settings` scene.
- **`VideoViewModel`** — Central state and logic: video loading (AVFoundation), playback, crop rect management, overlay image handling, and export pipeline. Export uses `AVMutableVideoComposition` with CIImage-based frame processing to apply crop, rounded-corner mask, and overlay compositing per-frame.
- **`ContentView`** — Root view. Owns the `VideoViewModel`, handles file import/drop, toolbar, alerts, and onboarding overlay.
- **`VideoPreviewView`** — Main canvas. Composes the sidebar, video layers, crop overlay, and player controls.
- **`VideoPreviewGeometry`** — Pure geometry helper that computes display frame, scale factor, and layer offsets for mapping between video-pixel coordinates and screen coordinates. Used throughout preview views.

### Views organization

- `Views/Core/` — `ContentView`, `VideoPreviewView` (main layout)
- `Views/Components/` — Reusable pieces: `SidebarView` (radius/overlay controls), `DropZoneView`, `CropOverlayView`, `RoundedVideoLayerView`, `OverlayLayerView`, `PlayerControlsView`, `CheckerboardView`, `OnboardingView`
- `Views/Modals/` — `HelpView`, `SettingsView`
- `Utilities/` — `DesignSystem` (centralized colors, typography, spacing, sizing tokens), `VideoPreviewGeometry`

### Design System

All UI styling goes through `DesignSystem` (`Utilities/DesignSystem.swift`). Use `DesignSystem.Colors`, `DesignSystem.Typography`, `DesignSystem.Spacing`, etc. instead of hardcoded values. Colors use a dark green accent (`#0A2903`) with light green secondary (`#347232`).

### Coordinate Systems

The codebase handles two coordinate systems:
- **SwiftUI / crop rect:** Y-down (origin top-left)
- **CIImage / export:** Y-up (origin bottom-left)

Conversions happen in `VideoViewModel.performExport()` and `VideoPreviewGeometry`. When modifying crop or overlay positioning, pay attention to which coordinate system you're in.

### Export Pipeline

Export in `VideoViewModel.performExport()` processes each frame through CIImage:
1. Apply track transform (for vertical videos)
2. Crop to `cropRect`
3. Apply rounded-corner mask via `CIBlendWithMask`
4. Composite onto a canvas sized to fit both video and overlay
5. Composite PNG overlay on top

Output format is always HEVC with alpha channel (`AVAssetExportPresetHEVCHighestQualityWithAlpha`).
