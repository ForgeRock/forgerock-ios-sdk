//
//  FRSession.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit
import FRAuth

extension FRSession {
    
    /// Invokes /authenticate endpoint in AM with predefined UI elements to go through Authentication Tree flow with `resumeURI` and `suspendedId` to resume Authentication Tree flow.
    /// - Parameters:
    ///   - resumeURI: Resume URI received in Email from Suspned Email Node; URI **must** contain `suspendedId` in URL query parameter
    ///   - rootViewController: root viewController which will initiate navigation flow
    ///   - completion: NodeCompletion callback which returns the result of Session Token as Token object
    public static func authenticateWithUI(_ resumeURI: URL, _ rootViewController: UIViewController, completion:@escaping NodeUICompletion<Token>) {
        if let _ = FRAuth.shared {
            FRSession.authenticate(resumeURI: resumeURI) { (token: Token?, node, error) in
                if let node = node {
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        let authViewController = AuthStepViewController(node: node, uiCompletion: completion, nibName: "AuthStepViewController")
                        let navigationController = UINavigationController(rootViewController: authViewController)
                        navigationController.navigationBar.tintColor = UIColor.white
                        navigationController.navigationBar.barTintColor = FRUI.shared.primaryColor
                        navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                        rootViewController.present(navigationController, animated: true, completion: nil)
                    }
                }
                else {
                    completion(token, error)
                }
            }
        } else {
            FRLog.w("Invalid SDK State")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Invokes /authenticate endpoint in AM with predefined UI elements to go through Authentication Tree flow with PolicyAdvice object which contains information about Authorization and/or Transactional Authorization
    /// - Parameter policyAdvice: PolicyAdvice object containing authorization information
    /// - Parameter rootViewController: root viewController which will initiate navigation flow
    /// - Parameter completion: NodeCompletion callback which returns the result of Session Token as Token object
    public static func authenticateWithUI(_ policyAdvice: PolicyAdvice, _ rootViewController:UIViewController, completion:@escaping NodeUICompletion<Token>) {
        if let _ = FRAuth.shared {
            FRSession.authenticate(policyAdvice: policyAdvice) { (token: Token?, node, error) in
                if let node = node {
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        let authViewController = AuthStepViewController(node: node, uiCompletion: completion, nibName: "AuthStepViewController")
                        let navigationController = UINavigationController(rootViewController: authViewController)
                        navigationController.navigationBar.tintColor = UIColor.white
                        navigationController.navigationBar.barTintColor = FRUI.shared.primaryColor
                        navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                        rootViewController.present(navigationController, animated: true, completion: nil)
                    }
                }
                else {
                    completion(token, error)
                }
            }
        } else {
            FRLog.w("Invalid SDK State")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Invokes /authenticate endpoint in AM with predefined UI elements to go through Authentication Tree flow with specified authIndexValue and authIndexType; authIndexType is an optional parameter defaulted to 'service' if not defined
    /// - Parameter authIndexValue: authIndexValue; Authentication Tree name value in String
    /// - Parameter authIndexType: authIndexType; Authentication Tree type value in String
    /// - Parameter rootViewController: root viewController which will initiate navigation flow
    /// - Parameter completion: NodeCompletion callback which returns the result of Session Token as Token object
    public static func authenticateWithUI(_ authIndexValue: String, _ authIndexType: String, _ rootViewController:UIViewController, completion:@escaping NodeUICompletion<Token>) {
        if let _ = FRAuth.shared {
            FRSession.authenticate(authIndexValue: authIndexValue, authIndexType: authIndexType) { (token: Token?, node, error) in
                
                if let node = node {
                    //  Perform UI work in the main thread
                    DispatchQueue.main.async {
                        let authViewController = AuthStepViewController(node: node, uiCompletion: completion, nibName: "AuthStepViewController")
                        let navigationController = UINavigationController(rootViewController: authViewController)
                        navigationController.navigationBar.tintColor = UIColor.white
                        navigationController.navigationBar.barTintColor = FRUI.shared.primaryColor
                        navigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                        rootViewController.present(navigationController, animated: true, completion: nil)
                    }
                }
                else {
                    completion(token, error)
                }
            }
        } else {
            FRLog.w("Invalid SDK State")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
}


@objc public class FRSessionObjc: NSObject {

    // - MARK: Objective-C Compatibility

    @objc(authenticateWithUI:authIndexType:rootViewController:userCompletion:)
    @available(swift, obsoleted: 1.0)
    public static func authenticate(_ authIndexValue: String, _ authIndexType: String, _ rootViewController: UIViewController, completion:@escaping NodeUICompletion<Token>) {
        
        FRSession.authenticateWithUI(authIndexValue, authIndexType, rootViewController) { (token: Token?, error) in
            completion(token, error)
        }
    }
}
