//
//  SceneDelegate.swift
//  TT Match
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // The window and root view controller are created from Main.storyboard
        // via UISceneStoryboardFile in Info.plist.
        guard scene is UIWindowScene else { return }
    }
}
