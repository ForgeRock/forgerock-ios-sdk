//
//  GoogleSignInHandler.swift
//  FRGoogleSignIn
//
//  Copyright (c) 2021-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import FRCore
import FRAuth
import GoogleSignIn

/**
 GoogleSignInHandler is responsible to perform sign-in and authorize a user using Google account
 */
public class GoogleSignInHandler: NSObject, IdPHandler {
    
    //  MARK: - Properties
    
    /// Credentials type for Google credentials
    public var tokenType: String = "id_token"
    
    /// Currently presented UIViewController in the application which will be used to present Google login view
    public var presentingViewController: UIViewController?
    
    /// Completion callback to notify the result
    var completionCallback: SocialLoginCompletionCallback?
    
    /// Module name string
    let module: String = "[FRGoogleSignIn]"
    
    //  MARK: - Protocol
    
    /// Signs-in a user through `GoogleSignIn` SDK
    /// - Parameters:
    ///   - idpClient: `IdPClient` information
    ///   - completion: Completion callback to notify the result
    public func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback) {
        Log.v("Start GIDSignIn sign-in flow", module: module)
        GIDSignIn.sharedInstance.signOut()
        self.completionCallback = completion
        if let viewController = self.presentingViewController {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: idpClient.clientId)
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                Log.v("GIDSignIn completed with result", module: self.module)
                if let error = error {
                    Log.e("An error ocurred during the authentication: \(error.localizedDescription)", module: self.module)
                }
                self.completionCallback?(result?.user.idToken?.tokenString, self.tokenType, error)
            }
        }
    }
        
    
    /// Generates, and returns `UIView` for `GIDSignInButton` button
    /// - Returns: `GIDSignInButton` button in `UIView`
    public func getProviderButtonView() -> UIView? {
        return self.getGoogleButtonView()
    }
    
    
    /// Generates, and returns `UIView` for `GIDSignInButton` button with `GIDSignInButtonSTyle`, and `GIDSignInButtonColorScheme` options
    /// - Parameters:
    ///   - style: `GIDSignInButtonStyle` option; default value with `.wide`
    ///   - colorScheme: `GIDSignInButtonColorScheme` option; default value with `.dark`
    /// - Returns: `GIDSignInButton` button in `UIView`
    public func getGoogleButtonView(style: GIDSignInButtonStyle = .wide, colorScheme: GIDSignInButtonColorScheme = .dark) -> UIView? {
        let btn = GIDSignInButton()
        btn.style = style
        btn.colorScheme = colorScheme
        return btn
    }
}
