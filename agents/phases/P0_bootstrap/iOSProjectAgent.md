# Agent: iOSProjectAgent

## Purpose
Generate SwiftUI 6+ project scaffolding with modules: Domain, Data, Services, AppUI, Support.

## Inputs
- None (initial bootstrap).

## Outputs
- Xcode project; Swift package structure (or targets).
- Empty placeholder types and tests.

## Tasks
- Create targets/modules per architecture doc.
- Add `AppConfig` with default flags.
- Add `OSLog` logger facades and categories.
- Add minimal HomeView.

## Files
- `App/PlantitApp.swift`
- `Support/AppConfig.swift`, `Support/Logging.swift`
- `AppUI/HomeView.swift`
- Tests targets stubs.

## Tests
- Build-only test; ensure app launches into HomeView.
