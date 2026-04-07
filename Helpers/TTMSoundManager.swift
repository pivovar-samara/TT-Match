//
//  TTMSoundManager.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 05.05.16.
//

import UIKit
import AVFoundation

enum TTMSoundType: Int {
    case win, tap, tapServiceChanged, newGame, cancel, warning
}

class TTMSoundManager: NSObject {

    static let sharedManager = TTMSoundManager()

    fileprivate let pathForFiles = "/System/Library/Audio/UISounds"
    fileprivate var audioFilesList = [URL]()
    fileprivate var audioFiles: [Int: String] = [
        TTMSoundType.win.rawValue: "Fanfare.caf",
        TTMSoundType.tap.rawValue: "Tock.caf",
        TTMSoundType.tapServiceChanged.rawValue: "payment_success.caf",
        TTMSoundType.newGame.rawValue: "Swish.caf",
        TTMSoundType.cancel.rawValue: "Tink.caf",
        TTMSoundType.warning.rawValue: "Suspense.caf"
    ]

    // Retains the player for the duration of playback.
    // Replaced on each new sound — acceptable because all sounds are short (< 1 s).
    fileprivate var currentPlayer: AVAudioPlayer?

    override init() {
        super.init()
        self.loadAudioFiles()
    }
}

// MARK: Public methods
extension TTMSoundManager {
    func playSystemSound(type: TTMSoundType, vibration: Bool = false) {
        if let soundName = self.audioFiles[type.rawValue] {
            for soundUrl in self.audioFilesList {
                if soundUrl.lastPathComponent == soundName {
                    self.playSound(soundUrl, vibration: vibration)
                }
            }
        }
    }
}

// MARK: Private methods
extension TTMSoundManager {
    fileprivate func playSound(_ soundURL: URL, vibration: Bool) {
        // AVAudioPlayer routes through the active AVAudioSession (.playback),
        // so playback volume tracks the media volume set by the user's volume
        // buttons — unlike AudioServicesPlaySystemSound, which uses ringer volume
        // and ignores the session entirely.
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            currentPlayer = player   // must be retained or playback stops immediately
            player.play()
        } catch {
            // File unreadable (e.g. the system sound was removed in a future OS).
            // Fail silently — missing audio is never fatal for a score tracker.
        }
        if vibration {
            // AVAudioPlayer has no vibration API; keep AudioServices for this path.
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }

    fileprivate func loadAudioFiles() {
        let audioValues = self.audioFiles.values
        let fileManager = FileManager()
        guard let directoryURL = URL(string: pathForFiles) else { return }
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: keys,
            options: []
        ) { (_, _) -> Bool in true }

        guard let enumerator = enumerator else { return }
        for case let url as URL in enumerator {
            if let values = try? url.resourceValues(forKeys: Set(keys)),
               values.isDirectory == false,
               !url.lastPathComponent.isEmpty,
               audioValues.contains(url.lastPathComponent) {
                self.audioFilesList.append(url)
            }
        }
    }
}
