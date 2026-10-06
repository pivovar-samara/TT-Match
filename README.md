# TT Match

An iOS app for tracking table tennis match scores. Built for quick, hands-free scorekeeping during real matches.

**Platform**: iPhone and iPad, iOS 17.0+ | **Language**: Swift 5

Releases and version history are on the [GitHub Releases](../../releases) page.

---

## Features

- **Match formats**: Best of 3, 5, or 7 games
- **Score tracking**: Points per game (default 11), games won per player
- **Serve rotation**: Automatically tracks who serves, including deuce rules (1 serve each at 10-10+); the first server is picked by tapping their score or at random
- **Side switching**: Players swap sides after every game and at the midpoint of the deciding game
- **Undo**: Long-press a score (or tap its undo button) to undo the last action; full history maintained throughout the match
- **Reset**: Tap the settings button during a match to start a new one
- **Persistence**: Match state is saved automatically and restored on next launch
- **Screen stays on** until the match is finished
- **Adaptive layout**: Light and dark mode, Liquid Glass controls on iOS 26+, iPad multitasking, and the iPhone Duo (layout around the fold; stand mode with the scoreboard on the top half)
- **VoiceOver**: Score buttons are labeled and score with the default accessibility action
- **Audio feedback**: Different sounds for scoring, serve changes, new games, and match win; volume tracks the media volume the user has set
- **Hands-free input**: Physical volume buttons score points — system HUD is suppressed and the actual volume level is never changed
- **Localization**: English and Russian

---

## Input Methods

| Action | Method |
|--------|--------|
| Choose first server | Tap that player's score button before the match starts |
| Randomize first server | Tap the serve randomizer before the match starts |
| Add point (left/right player) | Tap the player's score button |
| Add point (volume buttons) | Volume Up → right player, Volume Down → left player |
| Undo last action | Long-press either score button, or tap its undo button |
| Start the next game / match | Tap anywhere once a game or the match is finished |
| Change game count (best of 3/5/7) | Tap the settings button (shows the game count) before the match starts |
| Reset match | Tap the settings button during a match |

---

## Architecture

SwiftUI with an `@Observable` view model (`MatchViewModel`). Pure Swift — no Objective-C.

```
TT Match/
├── TTMatchApp.swift                # App entry point (SwiftUI App)
├── AppDelegate.swift               # Launch setup: Firebase, UI test mode
├── Config/
│   ├── Base.xcconfig               # Committed build config; optionally includes Secrets.xcconfig
│   └── Secrets.xcconfig.example    # Template for Firebase keys (Secrets.xcconfig is git-ignored)
├── ci_scripts/
│   └── ci_pre_xcodebuild.sh        # Xcode Cloud: generates Secrets.xcconfig from env vars
├── Controllers/
│   └── MatchViewModel.swift        # Screen logic: intents, tap lockout, analytics, UI state
├── Entities/
│   ├── TTMMatch.swift              # Core game state and logic (singleton)
│   └── TTMMatchSettings.swift      # Match configuration struct
├── Views/
│   ├── MatchScreen.swift           # The match screen, dialogs, volume buttons, iPhone Duo fold/stand layouts
│   ├── ScoreButton.swift           # Score button with undo control
│   ├── GamesStrip.swift            # Scores of completed games
│   └── RandomServeButton.swift     # Random first server picker
├── Helpers/
│   ├── TTMAnalytics.swift          # Firebase Analytics event wrappers
│   ├── TTMConfig.swift             # Global constants
│   ├── TTMFoldLayout.swift         # Layout geometry around the iPhone Duo fold
│   ├── TTMUITestSupport.swift      # -UITesting launch mode: clean state, seeded match, no Firebase
│   ├── TTMHelper.swift             # Localization and delay helpers
│   ├── TTMSoundManager.swift       # AVAudioPlayer-based sound playback (singleton)
│   └── TTMVolumeButtonHandler.swift # Volume button interception; suppresses system HUD
├── Extensions/
│   ├── ColorExtensions.swift       # SwiftUI app colors
│   ├── FontExtensions.swift        # SwiftUI app fonts
│   ├── UIColorExtensions.swift     # App color palette (UIKit)
│   ├── UIFontExtensions.swift      # Font used to size the score
│   └── ViewExtensions.swift        # Circular control background (Liquid Glass on iOS 26+)
└── Resources/
    ├── Localizable.xcstrings       # String catalog (EN + RU)
    └── Assets.xcassets
```

**Key design decisions:**
- `TTMMatch` is a singleton persisted to `UserDefaults` under the key `"TTMMatch"`
- Volume button interception uses KVO on `AVAudioSession.outputVolume`; a hidden `MPVolumeView` in the key window suppresses the system HUD; volume is silently restored to the pre-press level after each detected press so the system volume never visibly changes
- App sounds play via `AVAudioPlayer` on the same `.playback` session, so they automatically respect the media volume the user has set
- Font size in score buttons is computed so "00" fills the available width
- Layout follows the window size (`GeometryReader`), not the device model, so it adapts to iPad multitasking and the iPhone Duo opening, closing or standing half open

---

## Requirements

- Xcode 27
- iOS 17.0+ deployment target (Xcode's recommended target)
- Swift Package Manager: Firebase (`FirebaseAnalytics`, `FirebaseCrashlytics`) — resolved automatically by Xcode; no CocoaPods

---

## Building

Open `TT Match.xcodeproj` in Xcode and run on a device or simulator. Xcode resolves the Firebase packages on first open.

Firebase is optional for local builds: without keys the app runs normally and simply skips `FirebaseApp.configure`. To enable Analytics and Crashlytics locally, copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and fill in the values from your `GoogleService-Info.plist`. On Xcode Cloud, `ci_scripts/ci_pre_xcodebuild.sh` generates this file from the `FIREBASE_*` workflow environment variables.

iPhone runs in **landscape only**. iPad supports all orientations.

---

## Tests

- `TT MatchTests` — Swift Testing unit tests: match logic (serve rotation, deuce, game/match end, side switching, undo, persistence), settings, `MatchViewModel` intents and analytics, score font sizing, fold layout
- `TT MatchUITests` — XCUITest scenarios: scoring, undo, settings and reset dialogs. Tests can start from a preset score via `MatchSeed` instead of playing up to it

The scheme has two test plans: `CITests` (default, unit tests only — fast) and `FullTests` (unit + UI, ~3 min).

```bash
xcodebuild test -project "TT Match.xcodeproj" -scheme "TT Match" -destination 'platform=iOS Simulator,name=iPhone 17' -collect-test-diagnostics never -testPlan FullTests
```

---

## Localization

All string keys live in `Resources/Localizable.xcstrings` (Xcode String Catalog). The helper `L(_:)` in `TTMHelper.swift` wraps `NSLocalizedString`. When adding a new string, open the catalog in Xcode and add both the `en` and `ru` translations, or edit the JSON directly.

---

## Known Limitations

- Single-match tracking only — no match history or statistics
