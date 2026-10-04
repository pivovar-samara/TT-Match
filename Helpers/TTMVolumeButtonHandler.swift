//
//  TTMVolumeButtonHandler.swift
//  TT Match
//
//  Pure-Swift replacement for the abandoned JPSVolumeButtonHandler ObjC library.
//
//  Behaviour:
//  • Detects volume-up / volume-down button presses via KVO on
//    AVAudioSession.outputVolume.
//  • Suppresses the system volume HUD by keeping a visible MPVolumeView in the
//    key window (the standard technique; works through iOS 18).
//  • After each detected press the volume is silently restored to exactly the
//    level it was at *before* the press, so the system volume never appears to
//    change from the user's perspective.
//

import AVFoundation
import MediaPlayer
import UIKit

final class TTMVolumeButtonHandler {

    // MARK: - Public

    var upBlock: (() -> Void)?
    var downBlock: (() -> Void)?

    // MARK: - Private

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?

    // Placed far off-screen so it is never visible, but its *presence* in the
    // key-window hierarchy tells iOS not to show the system volume HUD.
    private let volumeView = MPVolumeView(frame: CGRect(
        x: CGFloat.greatestFiniteMagnitude,
        y: CGFloat.greatestFiniteMagnitude,
        width: 0, height: 0))

    // The volume we last wrote programmatically. Used to recognise and skip
    // the KVO callback that our own slider change fires.
    // Starts at -1 ("not set yet") so it never accidentally matches a real value.
    private var lastSetVolume: Float = -1

    private var isStarted = false
    private var disableHUD = false
    private var isObserving = false   // guards against duplicate observer registration
    private var appIsActive = true
    private var isAdjustingEdgeVolume = false

    // Tiny margin from 0 and 1 so there is always headroom to detect a press
    // in both directions even when the user's volume is at an extreme.
    private let maxVolume: Float = 0.99999
    private let minVolume: Float = 0.00001

    // MARK: - Init / deinit

    init(up upBlock: (() -> Void)? = nil, downBlock: (() -> Void)? = nil) {
        self.upBlock = upBlock
        self.downBlock = downBlock
    }

    deinit {
        stop()
        volumeView.removeFromSuperview()
    }

    // MARK: - Public API

    func start(_ disableSystemVolumeHUD: Bool) {
        guard !isStarted else { return }
        isStarted = true
        disableHUD = disableSystemVolumeHUD

        if disableSystemVolumeHUD {
            addVolumeViewToKeyWindow()
            // Must be visible (not hidden) for HUD suppression to work.
            volumeView.isHidden = false
        }

        setupSession()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        isObserving = false
        observation = nil
        volumeView.isHidden = true
        NotificationCenter.default.removeObserver(self)
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Session setup

    private func setupSession() {
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            clampEdgeVolumeIfNeeded()
            try session.setActive(true)
        } catch {
            return
        }

        // Replace any existing observation (safe: the old NSKeyValueObservation
        // is released and automatically unregisters itself).
        observation = session.observe(\.outputVolume,
                                       options: [.old, .new]) { [weak self] _, change in
            self?.volumeChanged(old: change.oldValue, new: change.newValue)
        }

        // Guard prevents duplicate entries if setupSession is ever called again.
        guard !isObserving else { return }
        isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    // MARK: - Volume helpers

    /// Nudges the volume away from 0 or 1 only when necessary, so both
    /// directions remain detectable. Does nothing if already within range.
    private func clampEdgeVolumeIfNeeded() {
        let current = session.outputVolume
        if current > maxVolume {
            isAdjustingEdgeVolume = true
            lastSetVolume = maxVolume
            setSystemVolume(maxVolume)
        } else if current < minVolume {
            isAdjustingEdgeVolume = true
            lastSetVolume = minVolume
            setSystemVolume(minVolume)
        }
        // Volume is already in range — leave it completely untouched.
    }

    private func volumeChanged(old: Float?, new: Float?) {
        guard appIsActive, let newVolume = new, let oldVolume = old else { return }

        // Skip the KVO callback triggered by our own programmatic reset.
        if lastSetVolume >= 0 && abs(newVolume - lastSetVolume) < 0.0001 {
            lastSetVolume = -1
            return
        }

        // Skip spurious callbacks during the initial edge clamp.
        if isAdjustingEdgeVolume {
            if newVolume == maxVolume || newVolume == minVolume { return }
            isAdjustingEdgeVolume = false
        }

        // Invoke the appropriate block.
        if newVolume > oldVolume {
            upBlock?()
        } else {
            downBlock?()
        }

        // Silently restore the volume to exactly what it was before the press.
        // Using oldVolume (not a stored initial value) means the volume never
        // drifts regardless of any prior manual changes the user made.
        lastSetVolume = oldVolume
        setSystemVolume(oldVolume)
    }

    /// Drives the MPVolumeView's internal UISlider to change system volume
    /// without showing any HUD. This is the only non-deprecated approach
    /// available on the public SDK.
    private func setSystemVolume(_ volume: Float) {
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                DispatchQueue.main.async { slider.value = volume }
                return
            }
        }
    }

    /// Inserts the off-screen MPVolumeView into the foreground key window.
    /// Using UIWindowScene avoids the deprecated UIApplication.windows API.
    /// Falls back to any connected window scene: during viewDidLoad the scene
    /// is still foregroundInactive, so the window may not be key yet.
    private func addVolumeViewToKeyWindow() {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = windowScenes.first(where: { $0.activationState == .foregroundActive })
                 ?? windowScenes.first
        let window = scene?.windows.first(where: { $0.isKeyWindow })
                  ?? scene?.windows.first
        window?.addSubview(volumeView)
    }

    // MARK: - Notification handlers

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            type == .ended
        else { return }
        try? session.setActive(true)
    }

    @objc private func appDidBecomeActive() {
        appIsActive = true
        guard isStarted else { return }
        // Attach the volume view if no window was available when start() ran.
        if disableHUD && volumeView.superview == nil { addVolumeViewToKeyWindow() }
        // Re-check edge clamping — volume may have changed while in background.
        clampEdgeVolumeIfNeeded()
    }

    @objc private func appWillResignActive() {
        appIsActive = false
    }
}
