//
//  AppDelegate.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

