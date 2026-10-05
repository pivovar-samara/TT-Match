//
//  TTMatchApp.swift
//  TT Match
//

import SwiftUI

@main
struct TTMatchApp: App {

    // Firebase and the UI test setup run in application(_:didFinishLaunchingWithOptions:).
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            MatchScreen()
        }
    }
}
