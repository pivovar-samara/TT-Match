//
//  AppDelegate.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TTMUITestSupport.prepareIfNeeded()
        if !TTMUITestSupport.isUITesting {
            configureFirebase()
        }
        return true
    }

    private func configureFirebase() {
        let info = Bundle.main.infoDictionary ?? [:]
        guard
            let apiKey = info["FIREBASE_API_KEY"] as? String, !apiKey.isEmpty,
            let gcmSenderID = info["FIREBASE_GCM_SENDER_ID"] as? String, !gcmSenderID.isEmpty,
            let projectID = info["FIREBASE_PROJECT_ID"] as? String, !projectID.isEmpty,
            let storageBucket = info["FIREBASE_STORAGE_BUCKET"] as? String, !storageBucket.isEmpty,
            let googleAppID = info["FIREBASE_GOOGLE_APP_ID"] as? String, !googleAppID.isEmpty
        else { return }

        let options = FirebaseOptions(googleAppID: googleAppID, gcmSenderID: gcmSenderID)
        options.apiKey = apiKey
        options.projectID = projectID
        options.storageBucket = storageBucket
        options.bundleID = Bundle.main.bundleIdentifier ?? ""
        FirebaseApp.configure(options: options)
        // Analytics is enabled but no userID or user properties are set anywhere —
        // only aggregate, non-identifying event data is collected.
        // IDFV collection is disabled via Info.plist (GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED = false).
        // Crashlytics starts automatically once FirebaseApp is configured.
    }
}
