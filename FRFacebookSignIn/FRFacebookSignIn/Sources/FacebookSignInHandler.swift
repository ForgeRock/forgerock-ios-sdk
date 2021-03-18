//
//  FacebookSignInHandler.swift
//  FRFacebookSignIn
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import FRAuth
import FRCore
import FBSDKLoginKit


/**
 FacebookSignInHandler is responsible to perform sign-in and authorize a user using Facebook account
 */
public class FacebookSignInHandler: NSObject, IdPHandler {
    
    //  MARK: - Properties
    
    /// Credentials type for Facebook credentials
    public var tokenType: String = "access_token"
    
    /// Currently presented UIViewController in the application which will be used to present Facebook login view
    public var presentingViewController: UIViewController?
    
    /// Module name string
    let module: String = "[FRFacebookSignIn]"
    
    //  MARK: - Protocol
    
    /// Signs-in a user through `FacebookLogin` SDK
    /// - Parameters:
    ///   - idpClient: `IdPClient` information
    ///   - completion: Completion callback to notify the result
    public func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback) {
        
        //  Initialize Facebook LoginManager instance
        let manager = LoginManager()
        //  Perform logout to clear previously authenticated session
        manager.logOut()
        
        Log.v("Provided scope (\(idpClient.scopes ?? [])) will be added to authorization request for Facebook", module: module)
        //  Perform login using Facebook LoginManager
        manager.logIn(permissions: idpClient.scopes ?? [], from: self.presentingViewController) { (result, error) in
            
            //  Facebook SDK does not return an error when the operation is cancelled by user; return a specific error for cancellation
            if let result = result, result.isCancelled {
                Log.e("Sign-in with Facebook SDK is cancelled by user", module: self.module)
                completion(nil, nil, SocialLoginError.cancelled)
                return
            }
            if let error = error {
                Log.e("An error ocurred during the authentication: \(error.localizedDescription)", module: self.module)
            }
            completion(result?.token?.tokenString, self.tokenType, error)
        }
    }
    
    
    /// Generates, and returns `UIView` for `FBLoginButton` button
    /// - Returns: `FBLoginButton` button in `UIView`
    public func getProviderButtonView() -> UIView? {
        let btn = FBLoginButton()
        btn.loginTracking = .limited
        btn.tooltipColorStyle = .neutralGray
        return btn
    }
    
    
    //  MARK: - iOS 10 Support
    
    /// Handles incoming URL for Facebook Sign-in using SFSafariViewController
    ///
    ///  Note: This is only required to support iOS 10; this must be called at AppDelegate of the application
    ///
    /// - Parameters:
    ///   - application: UIApplication instance
    ///   - url: Incoming URL as in URL instance
    ///   - options: UIApplication.OpenURLOptions
    /// - Returns: Boolean result whether or not the URL is designated for Facebook Login
    public static func handle(_ application: UIApplication, _ url: URL, _ options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ApplicationDelegate.shared.application(application, open: url, options: options)
    }
}
