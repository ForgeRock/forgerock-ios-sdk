//
//  SceneDelegate.swift
//  FRExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        for context in connectionOptions.urlContexts {
            handleURL(context.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handleURL(context.url)
        }
    }

    // MARK: - Helpers

    private func handleURL(_ url: URL) {
        var resumeURL: URL?
        if let resumeURI = url.valueOf("resumeURI"), let thisURI = URL(string: resumeURI) {
            resumeURL = thisURI
        } else if url.valueOf("suspendedId") != nil {
            resumeURL = url
        }

        if let resumeURL = resumeURL {
            if let rootViewController = window?.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                FRSession.authenticateWithUI(resumeURL, currentController) { (token: Token?, error) in
                    if let error = error {
                        FRLog.e(error.localizedDescription)
                    } else {
                        FRLog.i("Authenticate with ResumeURI successful: \(String(describing: token))")
                    }
                }
            }
        } else if Browser.validateBrowserLogin(url: url) {
            FRLog.w("Incoming URL from native Safari App")
        }
    }
}
