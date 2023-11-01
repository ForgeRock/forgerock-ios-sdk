//
//  AppDelegate.swift
//  BioExample
//
//  Created by George Bafaloukas on 07/07/2021.
//

// Swift
//
// AppDelegate.swift
import UIKit
import FRAuth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Parse and validate URL, extract authorization code, and continue the flow:
        return Browser.validateBrowserLogin(url: url)
    }
    
    
}
