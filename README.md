# TT Match

An iOS app for tracking table tennis match scores. Built for quick, hands-free scorekeeping during real matches.

**Version**: 1.1.2 | **Platform**: iOS 17.0+ | **Language**: Swift 5

---

## Features

- **Match formats**: Best of 3, 5, or 7 games
- **Score tracking**: Points per game (default 11), games won per player
- **Serve rotation**: Automatically tracks who serves, including deuce rules (1 serve each at 10-10+)
- **Undo**: Long-press to undo the last point; full history maintained throughout the match
- **Reset**: Tap the settings button during a match to start a new one
- **Persistence**: Match state is saved automatically and restored on next launch
- **Audio feedback**: Different sounds for scoring, serve changes, new games, and match win; volume tracks the media volume the user has set
- **Hands-free input**: Physical volume buttons score points — system HUD is suppressed and the actual volume level is never changed
- **Localization**: English and Russian

---

## Input Methods

| Action | Method |
|--------|--------|
| Add point (left/right player) | Tap the player's score button |
| Add point (volume buttons) | Volume Up → right player, Volume Down → left player |
| Undo last point | Long-press either score button |
| Reset match | Tap settings button during a match |
| Change game count | Tap settings icon |
| Randomize first server | Tap the serve indicator before match starts |

---

## Architecture

Standard MVC pattern with UIKit. Pure Swift — no Objective-C.

```
TT Match/
├── AppDelegate.swift               # App entry point; configures Firebase
├── SceneDelegate.swift
├── Config/
│   ├── Base.xcconfig               # Committed build config; optionally includes Secrets.xcconfig
│   └── Secrets.xcconfig.example    # Template for Firebase keys (Secrets.xcconfig is git-ignored)
├── ci_scripts/
│   └── ci_pre_xcodebuild.sh        # Xcode Cloud: generates Secrets.xcconfig from env vars
├── Controllers/
│   └── ViewController.swift        # Main UI; handles all user input
├── Entities/
│   ├── TTMMatch.swift              # Core game state and logic (singleton)
│   └── TTMMatchSettings.swift      # Match configuration struct
├── Views/
│   ├── TTMSelectableButton         # Score button with embedded undo control
│   ├── TTMGameCell                 # Table cell showing completed game scores
│   └── TTMTextField                # Text field used for keyboard management
├── Helpers/
│   ├── TTMAnalytics.swift          # Firebase Analytics event wrappers
│   ├── TTMConfig.swift             # Global constants
│   ├── TTMHelper.swift             # Device detection, localization, async helpers
│   ├── TTMSoundManager.swift       # AVAudioPlayer-based sound playback (singleton)
│   └── TTMVolumeButtonHandler.swift # Volume button interception; suppresses system HUD
├── Extensions/
│   ├── UIColorExtensions.swift     # App color palette
│   ├── UIFontExtensions.swift      # Adaptive font weights
│   └── UIImageExtensions.swift     # Image-from-color, tinting
└── Resources/
    ├── Main.storyboard
    ├── Localizable.xcstrings       # String catalog (EN + RU)
    └── Assets.xcassets
```

**Key design decisions:**
- `TTMMatch` is a singleton persisted to `UserDefaults` under the key `"TTMMatch"`
- Volume button interception uses KVO on `AVAudioSession.outputVolume`; a hidden `MPVolumeView` in the key window suppresses the system HUD; volume is silently restored to the pre-press level after each detected press so the system volume never visibly changes
- App sounds play via `AVAudioPlayer` on the same `.playback` session, so they automatically respect the media volume the user has set
- Font size in score buttons is computed via binary search to fill available width

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

## Localization

All string keys live in `Resources/Localizable.xcstrings` (Xcode String Catalog). The helper `L(_:)` in `TTMHelper.swift` wraps `NSLocalizedString`. When adding a new string, open the catalog in Xcode and add both the `en` and `ru` translations, or edit the JSON directly.

---

## Known Limitations

- No automated tests
- Single-match tracking only — no match history or statistics
