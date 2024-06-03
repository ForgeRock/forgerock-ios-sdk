//
//  FacebookSignInHandler.swift
//  FRFacebookSignIn
//
//  Copyright (c) 2021-2023 ForgeRock. All rights reserved.
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
    
    /// `LoginManager` instance for Facebook SDK
    var manager: LoginManager
    
    
    //  MARK: - Init
    
    public override init() {
        //  Initialize Facebook LoginManager instance
        self.manager = LoginManager()
        //  Perform logout to clear previously authenticated session
        self.manager.logOut()
        
        super.init()
    }
    
    //  MARK: - Protocol
    
    /// Signs-in a user through `FacebookLogin` SDK
    /// - Parameters:
    ///   - idpClient: `IdPClient` information
    ///   - completion: Completion callback to notify the result
    public func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback) {
        
//        Settings.shared.isAdvertiserTrackingEnabled = true
//        
        Log.v("Provided scope (\(idpClient.scopes ?? [])) will be added to authorization request for Facebook", module: module)
        
//        // LIMITED LOGIN !!!
//        guard let configuration = LoginConfiguration(
//            permissions: idpClient.scopes ?? [],
//            tracking: .limited,
//            nonce: "123"
//        )
//        else {
//            return
//        }
//        
//        self.manager.logIn(configuration: configuration) { result in
//            switch result {
//            case .success:
//                let tokenString = AccessToken.current?.tokenString
//                let idTokenString = AuthenticationToken.current?.tokenString
//                Log.i("ACCESS_TOKEN: \(String(describing: tokenString))", module: self.module)
//                Log.i("ID_TOKEN: \(String(describing: idTokenString))", module: self.module)
//                completion(tokenString, self.tokenType, nil)
//                return
//            case .cancelled:
//                Log.e("Sign-in with Facebook SDK is cancelled by user", module: self.module)
//                completion(nil, nil, SocialLoginError.cancelled)
//                return
//            case .failed(let error):
//                Log.e("An error ocurred during the authentication: \(error)", module: self.module)
//                completion(nil, nil, error)
//                return
//            }
//        }
        
        
        // CLASSIC LOGIN !!! (CURRENT)
        self.manager.logIn(permissions: idpClient.scopes ?? [], from: self.presentingViewController) { (result, error) in
            
            //  Facebook SDK does not return an error when the operation is cancelled by user; return a specific error for cancellation
            if let result = result, result.isCancelled {
                Log.e("Sign-in with Facebook SDK is cancelled by user", module: self.module)
                completion(nil, nil, SocialLoginError.cancelled)
                return
            }
            if let error = error {
                Log.e("An error ocurred during the authentication: \(error.localizedDescription)", module: self.module)
            }
            Log.i("TOKEN: \(String(describing: result?.token?.tokenString))")
            completion(result?.token?.tokenString, self.tokenType, error)
        }
    }
    
    
    /// Generates, and returns `UIView` for `FBLoginButton` button
    /// - Returns: `FBLoginButton` button in `UIView`
    public func getProviderButtonView() -> UIView? {
        return self.getFacebookButtonView()
    }
    
    
    /// Generates, and returns `UIView` for `FBLoginButton` button with `ColorStyle` option
    /// - Parameter colorStyle: `FBTooltipView.ColorStyle` option for `FBLoginButton`; default value with `.neutralGray`
    /// - Returns: `FBLoginButton` button in `UIView`
    public func getFacebookButtonView(colorStyle: FBTooltipView.ColorStyle = .neutralGray) -> UIView? {
        let btn = FBLoginButton()
        btn.tooltipColorStyle = colorStyle
        return btn
    }
    
    
    /// Call this method from the `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)` method of your application delegate. It should be invoked for the proper use of the Facebook SDK.
    /// As part of SDK initialization, basic auto-logging of app events will occur; this can be controlled via the `FacebookAutoLogAppEventsEnabled` key in the project's Info.plist file.
    ///
    /// - Parameters:
    ///   - application: The application as passed to `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.
    ///   - launchOptions: The launch options as passed to `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.
    /// - Returns: `true` if there are any added application observers that themselves return true from calling `application(_:didFinishLaunchingWithOptions:)`. Otherwise will return `false`.
    public static func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    

}
