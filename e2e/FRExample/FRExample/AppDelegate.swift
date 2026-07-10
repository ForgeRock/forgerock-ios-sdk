//
//  AppDelegate.swift
//  FRExample
//
//  Copyright (c) 2019 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth
import FRCore
#if canImport(FRFacebookSignIn)
import FRFacebookSignIn
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if canImport(FRFacebookSignIn)
        _ = FacebookSignInHandler.application(application, didFinishLaunchingWithOptions: launchOptions)
        #endif
        FRLog.setLogLevel([.all])
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

extension URL {
    func valueOf(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}
