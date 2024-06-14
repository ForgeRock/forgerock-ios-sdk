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
    
    //  This method is one of AppDelegate protocol that is invoked when iOS tries to open the app using the app's dedicated URL
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let resumeURL = url // validate the resumeURI contains 'suspendedId' parameter
        
        //  With given resumeURI, use FRSession to resume authenticate flow
        FRSession.authenticate(resumeURI: resumeURL) { (token: Token?, node, error) in
            //  Handle Node, or the result of continuing the the authentication flow
        }
        
        return true
    }
    
    
}
