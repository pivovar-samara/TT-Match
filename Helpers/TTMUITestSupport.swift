//
//  TTMUITestSupport.swift
//  TT Match
//

import UIKit

/// Prepares the app for UI tests when launched with the `-UITesting` argument.
/// `TTM_UITEST_MATCH` may hold a JSON match in the same format `TTMMatch.save()` writes,
/// so a test can start from a given score instead of tapping its way there.
enum TTMUITestSupport {

    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")

    /// Must run before the first access to `TTMMatch.currentMatch`.
    static func prepareIfNeeded() {
        guard isUITesting else { return }

        UIView.setAnimationsEnabled(false)

        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "TTMMatch")

        if let json = ProcessInfo.processInfo.environment["TTM_UITEST_MATCH"],
           let data = json.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            userDefaults.set(dict, forKey: "TTMMatch")
        }
    }
}
