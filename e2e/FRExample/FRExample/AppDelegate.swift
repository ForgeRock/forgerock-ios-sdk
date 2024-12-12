//
//  AppDelegate.swift
//  FRExample
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
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

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if canImport(FRFacebookSignIn)
            FacebookSignInHandler.application(application, didFinishLaunchingWithOptions: launchOptions)
        #endif
        // Enable logs for all level
        FRLog.setLogLevel([ .all])
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        var resumeURL: URL?
        if let resumeURI = url.valueOf("resumeURI"), let thisURI = URL(string: resumeURI) {
            resumeURL = thisURI
        }
        else if let _ = url.valueOf("suspendedId") {
            resumeURL = url
        }
        
        if let resumeURL = resumeURL {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                
                FRSession.authenticateWithUI(resumeURL, currentController) { (token: Token?, error) in
                    if let error = error {
                        FRLog.e(error.localizedDescription)
                    }
                    else {
                        FRLog.i("Authenticate with ResumeURI successful: \(String(describing: token))")
                    }
                }
            }
        }
        else if Browser.validateBrowserLogin(url: url) {
            FRLog.w("Incoming URL from native Safari App")
            return true
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension URL {
    func valueOf(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

