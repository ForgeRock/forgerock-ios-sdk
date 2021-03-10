//
//  AuthService.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import FRAuth

public typealias NodeUICompletion<T> = (_ result: T?, _ error:Error?) -> Void

extension AuthService {
    
    /// Authenticates a new user with pre-defined UI, and viewControllers pre-built in FRUI framework
    ///
    /// - Parameters:
    ///   - rootViewController: root viewController which will initiate navigation flow
    ///   - completion: completion callback block that notifies the result of the flow
    public func authenticateWithUI<T>(_ rootViewController:UIViewController, completion:@escaping NodeUICompletion<T>) {
        
        self.next { (result: T?, node, error) in
            
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
                completion(result, error)
            }
        }
    }
}
