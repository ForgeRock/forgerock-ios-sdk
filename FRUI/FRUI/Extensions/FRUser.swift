//
//  FRUser.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

extension FRUser {
    
    /// Authenticates a new user with pre-defined UI, and viewControllers pre-built in FRUI framework
    ///
    /// - Parameters:
    ///   - rootViewController: root viewController which will initiate navigation flow
    ///   - completion: completion callback block that notifies the result of the flow
    public static func authenticateWithUI<T>(_ rootViewController:UIViewController, completion:@escaping NodeUICompletion<T>) {

        if let frAuth = FRAuth.shared {
            let authViewController = AuthStepViewController(auth: frAuth, flowType: .authentication, uiCompletion: completion, nibName: "AuthStepViewController")
            let navigationController = UINavigationController(rootViewController: authViewController)
            navigationController.navigationBar.tintColor = UIColor.white
            navigationController.navigationBar.barTintColor = FRUI.shared.primaryColor
            navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            rootViewController.present(navigationController, animated: true, completion: nil)
        } else {
            FRLog.w("Invalid SDK State")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Registers a new user with pre-defined UI, and viewControllers pre-built in FRUI framework
    ///
    /// - Parameters:
    ///   - rootViewController: root viewController which will initiate navigation flow
    ///   - completion: completion callback block that notifies the result of the flow
    public static func registerWithUI<T>(_ rootViewController: UIViewController, completion: @escaping NodeUICompletion<T>) {
        
        
        if let frAuth = FRAuth.shared {
            let authViewController = AuthStepViewController(auth: frAuth, flowType: .registration, uiCompletion: completion, nibName: "AuthStepViewController")
            let navigationController = UINavigationController(rootViewController: authViewController)
            navigationController.navigationBar.tintColor = UIColor.white
            navigationController.navigationBar.barTintColor = FRUI.shared.primaryColor
            navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            rootViewController.present(navigationController, animated: true, completion: nil)
        } else {
            FRLog.w("Invalid SDK State")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
}

/// FRUserObjc class is responsible to provide Objective-c compatibility for FRUser extension methods
@objc public class FRUserObjc: NSObject {
    
    
    // - MARK: Objective-C Compatibility
    
    @objc(authenticateWithRootViewController:userCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func authenticateWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<FRUser>) {
        FRUser.authenticateWithUI(rootViewController, completion: completion)
    }
    
    
    @objc(authenticateWithRootViewController:accessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func authenticateWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<AccessToken>) {
        FRUser.authenticateWithUI(rootViewController, completion: completion)
    }
    
    
    @objc(authenticateWithRootViewController:tokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func authenticateWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<Token>) {
        FRUser.authenticateWithUI(rootViewController, completion: completion)
    }
    
    
    @objc(registerWithRootViewController:userCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func registerWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<FRUser>) {
        FRUser.registerWithUI(rootViewController, completion: completion)
    }
    
    
    @objc(registerWithRootViewController:accessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func registerWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<AccessToken>) {
        FRUser.registerWithUI(rootViewController, completion: completion)
    }
    
    
    @objc(registerWithRootViewController:tokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func registerWithRootViewController(_ rootViewController: UIViewController, completion:@escaping NodeUICompletion<Token>) {
        FRUser.registerWithUI(rootViewController, completion: completion)
    }
}
