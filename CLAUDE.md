# CLAUDE.md — TT Match

Guidance for Claude Code when working in this repository.

---

## Project at a glance

- **Type**: iOS app (UIKit, MVC)
- **Language**: Pure Swift — no Objective-C
- **No external package manager** — no Podfile, no Package.swift; fully dependency-free
- **No test targets** — do not add tests unless the user explicitly asks

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
| UI layout | `Resources/Main.storyboard` + `Controllers/ViewController.swift` |
| Score button appearance | `Views/TTMSelectableButton.swift` |
| Completed game row | `Views/TTMGameCell.swift` |
| Audio | `Helpers/TTMSoundManager.swift` |
| Colors / fonts / images | `Extensions/` |
| App-level config | `Helpers/TTMConfig.swift` |
| Localized strings | `Resources/Localizable.xcstrings` |
| Volume button handling | `Helpers/TTMVolumeButtonHandler.swift` |

---

## Coding conventions

- Use `L("key")` (defined in `TTMHelper.swift`) instead of `NSLocalizedString` directly
- Device detection: use the global constants `IS_IPAD` and `IS_SMALL_SCREEN` (defined in `TTMHelper.swift`) — do not query `UIDevice` or `UIScreen` directly
- Delay helper: `delay(_:closure:)` (defined in `TTMHelper.swift`) wraps `DispatchQueue.main.asyncAfter` — call as `delay(0.3) { ... }`
- Colors: use `UIColor.ttmBlueColor`, `UIColor.ttmGreenColor`, `UIColor.ttmGrayColor` from extensions
- Fonts: use `UIFont.ttm*` class methods (e.g. `UIFont.ttmRegularOfSize()`)

---

## Architectural rules

- **Do not break the singleton pattern** for `TTMMatch` or `TTMSoundManager` — `ViewController` depends on `TTMMatch.currentMatch` being a shared instance
- **Do not add CocoaPods or SPM** unless the user explicitly requests it — this is intentionally dependency-free
- **Persistence is automatic**: model property changes trigger `didSet` which calls `save()` — do not add manual save calls in the controller
- **Volume button handling** is encapsulated in `TTMVolumeButtonHandler`. It owns the `AVAudioSession` (`.playback` + `.mixWithOthers`) and the hidden `MPVolumeView` (HUD suppression). `ViewController.viewDidLoad` creates the handler and calls `start(true)`. `TTMVolumeButtonHandler` is *not* a singleton — it is owned by `ViewController`

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

### Changing game settings defaults
Edit `TTMMatchSettings.swift` — the defaults are defined there as property initializers.

### Modifying serve logic
All serve logic lives in the `serve` computed property and related helpers in `TTMMatch.swift`. Read it carefully before editing — the deuce case (points ≥ `pointCount - 1` for both players) switches from 2-serve to 1-serve rotation.

### Adding a new player interaction
1. Add gesture recognizer or button action in `ViewController`
2. Call the appropriate method on `TTMMatch.currentMatch`
3. Update `ViewController.updateUI()` to reflect any new state

---

## Things to avoid

- Do not use `UserDefaults` keys other than `"TTMMatch"` for match state — the serialization/deserialization in `TTMMatch` uses that key exclusively
- Do not access `UIScreen.main.bounds` directly for layout decisions — use the `IS_SMALL_SCREEN` and `IS_IPAD` constants
- Do not add `print` or `NSLog` statements for debugging without removing them before finishing — the build phase already warns on TODO/FIXME
- Do not create new singleton classes without strong justification; the two existing ones (`TTMMatch`, `TTMSoundManager`) cover all shared state needs
- **Do not rename `gamesLabel` back to `subtitleLabel`** in `TTMSelectableButton` — `UIButton` gained a `subtitleLabel` property in iOS 15 and the name collision causes a compiler error
- Do not call `userDefaults.synchronize()` — it is a no-op since iOS 12 and will generate a deprecation warning
