# CLAUDE.md — TT Match

Guidance for Claude Code when working in this repository.

---

## Project at a glance

- **Type**: iOS app — SwiftUI screen (`MatchScreen`) hosted in a UIKit scene, being migrated from UIKit/storyboard
- **Language**: Pure Swift — no Objective-C
- **Dependencies**: Firebase via Swift Package Manager (`FirebaseAnalytics`, `FirebaseCrashlytics`), added in the Xcode project — no Podfile, no Package.swift
- **Tests**: `TT MatchTests` (Swift Testing, unit tests for `TTMMatch`/`TTMMatchSettings`) and `TT MatchUITests` (XCUITest). They are the safety net for the planned UIKit → SwiftUI migration — keep them passing and keep the accessibility identifiers they rely on
- **Deployment target**: `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` (iOS 17.0 with Xcode 27)

---

## Core domain concepts

**Match** (`TTMMatch.swift`):
- Singleton: `TTMMatch.currentMatch`
- Persisted to `UserDefaults` key `"TTMMatch"` via `didSet` property observers
- Tracks: current game scores, games won, full undo history, serve state
- Serve logic is non-trivial: 2 serves each normally, 1 each in deuce (both players at 10+); changes also occur at game boundaries

**Match settings** (`TTMMatchSettings.swift`):
- `pointCount`: points needed to win a game (default 11)
- `gameCount`: 3, 5, or 7 (best-of)
- `servesCount`: 2 normally, 1 at deuce

**Players** (`TTMMatchPlayer` enum in `TTMMatch.swift`):
- `.green` and `.blue` — color is the player identity, not a name

**Sound feedback** (`TTMSoundManager.swift`):
- 6 sound types mapped to system `.caf` files
- Singleton: `TTMSoundManager.sharedManager`
- Playback uses `AVAudioPlayer` on an `.playback` `AVAudioSession`, so volume tracks the user's media volume (not ringer volume)

---

## Key files and where to look

| What you need to change | File |
|-------------------------|------|
| Game logic / serve rules | `Entities/TTMMatch.swift` |
| Match configuration | `Entities/TTMMatchSettings.swift` |
| Screen logic (intents, tap lockout, analytics, UI state) | `Controllers/MatchViewModel.swift` |
| Screen layout, dialogs, volume buttons | `Views/MatchScreen.swift` (root view, created in `SceneDelegate`) |
| Score button appearance | `Views/ScoreButton.swift` |
| Completed game rows | `Views/GamesStrip.swift` |
| Serve randomizer | `Views/RandomServeButton.swift` |
| Audio | `Helpers/TTMSoundManager.swift` |
| Colors / fonts / images | `Extensions/` (`Color.ttm*`, `Font.ttm*` for SwiftUI) |
| App-level config | `Helpers/TTMConfig.swift` |
| Analytics events | `Helpers/TTMAnalytics.swift` |
| Firebase setup | `AppDelegate.swift` (`configureFirebase()`) |
| Firebase keys / build config | `Config/Base.xcconfig`, `Config/Secrets.xcconfig.example` |
| Xcode Cloud pre-build | `ci_scripts/ci_pre_xcodebuild.sh` |
| Localized strings | `Resources/Localizable.xcstrings` |
| Volume button handling | `Helpers/TTMVolumeButtonHandler.swift` |
| UI test launch mode / seeded match | `Helpers/TTMUITestSupport.swift` |
| Unit tests (fixture: `MatchFixture.swift`) | `TT MatchTests/` (app target files are not folder-synchronized — add new app sources to `project.pbxproj`; test targets are synchronized) |
| UI tests (base: `TTMUITestCase.swift`) | `TT MatchUITests/` |

---

## Coding conventions

- Use `L("key")` (defined in `TTMHelper.swift`) instead of `NSLocalizedString` directly
- Device detection: use the global constants `IS_IPAD` and `IS_SMALL_SCREEN` (defined in `TTMHelper.swift`) — do not query `UIDevice` or `UIScreen` directly
- Delay helper: `delay(_:closure:)` (defined in `TTMHelper.swift`) wraps `DispatchQueue.main.asyncAfter` — call as `delay(0.3) { ... }`
- Colors: in SwiftUI use `Color.ttmBlue`, `Color.ttmGreen`, `Color.ttmGray` and `TTMMatchPlayer.swiftUIColor`; in UIKit `UIColor.ttm*Color`
- Fonts: in SwiftUI use `Font.ttmBold/ttmHeavy/ttmBlack(_:)`; in UIKit `UIFont.ttm*` class methods

---

## Architectural rules

- **Do not break the singleton pattern** for `TTMMatch` or `TTMSoundManager` — `MatchViewModel()` defaults to `TTMMatch.currentMatch`, the shared instance
- **Do not add new dependencies** (SPM packages or CocoaPods) unless the user explicitly requests it — Firebase is the only one
- **Firebase is configured from build settings, not `GoogleService-Info.plist`**: keys come from `Config/Secrets.xcconfig` (git-ignored; generated on Xcode Cloud by `ci_scripts/ci_pre_xcodebuild.sh`) → Info.plist → `AppDelegate.configureFirebase()`. Missing keys mean Firebase is silently skipped. Never commit `Secrets.xcconfig` or real keys
- **Screen logic lives in `MatchViewModel`** (`@Observable`, `@MainActor`): user intents, the tap lockout, analytics and the derived UI state. Views only call its intents and render its state. `TTMMatch` is `@Observable` too, so views may read the match directly. `Controllers/ViewController.swift`, `Main.storyboard` and the `TTMSelectableButton`/`TTMGameCell` xibs are no longer used and are removed in the next migration step — do not change them
- **Analytics calls go through `TTMAnalytics`** — do not call `Analytics.logEvent` directly from controllers. `MatchViewModel` reports through the `TTMAnalyticsTracking` protocol (`TTMAnalyticsTracker` forwards to `TTMAnalytics`; tests pass a spy). Do not set user IDs or user properties; only aggregate, non-identifying events are collected (IDFV collection is disabled in Info.plist)
- **Persistence is automatic**: model property changes trigger `didSet` which calls `save()` — do not add manual save calls in the controller
- **Volume button handling** is encapsulated in `TTMVolumeButtonHandler`. It owns the `AVAudioSession` (`.playback` + `.mixWithOthers`) and the hidden `MPVolumeView` (HUD suppression). `MatchScreen` creates the handler on appear and calls `start(true)`. `TTMVolumeButtonHandler` is *not* a singleton — it is owned by `MatchScreen`

---

## Common tasks

### Adding a new sound
1. Add the sound type to the `TTMSoundType` enum in `TTMSoundManager.swift`
2. Map it to a system `.caf` filename by adding an entry to the `audioFiles: [Int: String]` dictionary in `TTMSoundManager`
3. Call `TTMSoundManager.sharedManager.playSystemSound(type: .yourType)` at the appropriate point

### Adding a localized string
1. Open `Resources/Localizable.xcstrings` in Xcode's String Catalog editor (or edit the JSON directly)
2. Add the key with both `en` and `ru` translations
3. Reference it with `L("your_key")`

### Testing
- Unit tests create matches via `MatchFixture` (isolated `UserDefaults` suite through `TTMMatch(userDefaults:)`) — never touch `TTMMatch.currentMatch` or `UserDefaults.standard` from tests
- `MatchViewModelTests` builds `MatchViewModel(match: fixture.match, analytics: AnalyticsSpy())`
- Unit test suites are `@MainActor` because `TTMMatch` plays sounds through the `TTMSoundManager` singleton
- UI tests launch with `-UITesting` (clean state, no Firebase, animations off). To start from a given score pass a `MatchSeed`, which goes to `TTM_UITEST_MATCH` in the same JSON format `TTMMatch.save()` writes. `restore()` resets a finished match, so seed one point before the event and tap once
- Accessibility identifiers used by UI tests: `score.left`/`score.right` (buttons, value = current score), `undo.left`/`undo.right` (only present once the serve is decided), `settings` (absent when the match is finished), `randomServe`, `game.N` (an `other` element, not a cell; value = `"left-right"` once the game is finished)
- SwiftUI hit testing: a clear `fill` is not tappable — give buttons with a transparent background a `contentShape`. Add/remove controls with `if` instead of toggling `opacity`/`allowsHitTesting`: that left the undo button untappable in UI tests
- On iPhone the `confirmationDialog`s appear as popovers without a Cancel button — dismiss with `dismissActionSheet()`
- `-collect-test-diagnostics never` is needed: otherwise `xcodebuild` hangs in `simctl diagnose` after UI tests
- The app ignores taps for `secondsToDeclineTaps` after each point/undo — use `tapAndSettle`
- Test plans: `CITests` (scheme default, unit only) and `FullTests` (unit + UI). UI tests are marked non-parallelizable in the plan and scheme: on simulator clones the UI test runner failed to launch. Full run: `xcodebuild test -project "TT Match.xcodeproj" -scheme "TT Match" -destination 'platform=iOS Simulator,name=iPhone 17' -collect-test-diagnostics never -testPlan FullTests`

### Changing game settings defaults
Edit `TTMMatchSettings.swift` — the defaults are defined there as property initializers.

### Modifying serve logic
All serve logic lives in the `serve` computed property and related helpers in `TTMMatch.swift`. Read it carefully before editing — the deuce case (points ≥ `pointCount - 1` for both players) switches from 2-serve to 1-serve rotation.

### Adding a new player interaction
1. Add an intent to `MatchViewModel` (it calls `TTMMatch` and reports analytics) and cover it in `MatchViewModelTests`
2. Add the gesture or button in the SwiftUI view that calls the intent
3. Expose any new UI state as a `MatchViewModel` property and read it in the view

---

## Things to avoid

- Do not use `UserDefaults` keys other than `"TTMMatch"` for match state — the serialization/deserialization in `TTMMatch` uses that key exclusively
- Do not access `UIScreen.main.bounds` directly for layout decisions — use the `IS_SMALL_SCREEN` and `IS_IPAD` constants
- Do not add `print` or `NSLog` statements for debugging without removing them before finishing — the build phase already warns on TODO/FIXME
- Do not create new singleton classes without strong justification; the two existing ones (`TTMMatch`, `TTMSoundManager`) cover all shared state needs
- **Do not rename `gamesLabel` back to `subtitleLabel`** in `TTMSelectableButton` — `UIButton` gained a `subtitleLabel` property in iOS 15 and the name collision causes a compiler error
- Do not call `userDefaults.synchronize()` — it is a no-op since iOS 12 and will generate a deprecation warning
