// 
//  AppleSignInHandler.swift
//  FRAuth
//
//  Copyright (c) 2021-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import AuthenticationServices

/**
 AppleSignInHandler is responsible to perform authorization/signing-in a user using Apple ID, and `AuthenticationServices` framework; Sign-in With Apple is only available for iOS 13 and above.
 */
public class AppleSignInHandler: NSObject, IdPHandler {
    
    //  MARK: - Properties
    
    /// Token type for Sign-in With Apple; id_token
    public var tokenType: String = "id_token"
    /// Currently displayed UIViewController in the application
    public var presentingViewController: UIViewController?
    /// Temporary completion callback to handle the response
    var completionCallback: SocialLoginCompletionCallback?
    
    private var acceptsJSON = false
    
    //  MARK: - Protocol
    
    /// Signs-in a user through `Sign-in With Apple` feature available in iOS 13 and above
    /// - Parameters:
    ///   - idpClient: `IdPClient` information
    ///   - completion: Completion callback to notify the result
    public func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback) {

        if #available(iOS 13.0, *) {
            //  Capture the completion block
            self.completionCallback = completion
            
            //  Create ASAuthorizationRequest instance with IdPClient
            let request = self.createASAuthorizationRequest(idpClient: idpClient)
            
            //  Create authorization controller, and perform the request
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
            
        }
        else {
            FRLog.e("Sign-in With Apple is not supported for the current iOS version: \(UIDevice.current.systemVersion) | \(UIDevice.current.model)")
            completion(nil, nil, SocialLoginError.notSupported("'Sign-in With Apple is only supported for iOS 13 and above"))
        }
    }
    
    
    /// Generates, and returns `UIView` for `Sign-in With Apple` button
    /// - Returns: `Sign-in With Apple` button in `UIView`
    public func getProviderButtonView() -> UIView? {
        if #available(iOS 13.0, *) {
            return self.getAppleButtonView()
        }
        else {
            FRLog.w("Sign-in With Apple is only supported for iOS 13 and above; returning nil for button view")
            return nil
        }
    }
    
    
    /// Generates, and returns `UIView` for `Sign-in With Apple` button with `ButtonType`, and `Style` options
    /// - Parameters:
    ///   - buttonType: `ASAuthorizationAppleIDButton.ButtonType` option; default value with `.signIn`
    ///   - style: `ASAuthorizationAppleIDButton.Style` option; default value with `.dark`
    /// - Returns: `Sign-in With Apple` button in `UIView`
    @available(iOS 13.0, *) public func getAppleButtonView(buttonType: ASAuthorizationAppleIDButton.ButtonType = .signIn, style: ASAuthorizationAppleIDButton.Style = .black) -> UIView? {
        return ASAuthorizationAppleIDButton(authorizationButtonType: buttonType, authorizationButtonStyle: style)
    }
    
    
    //  MARK: - Private
    
    /// Constructs `ASAuthorizationRequest` based on `IdPClient`
    /// - Parameter idpClient: `IdPClient` instance containing OAuth2 client information for the provider
    /// - Returns: `ASAuthorizationRequest` constructed based on the given provider's client information
    @available(iOS 13.0, *)
    func createASAuthorizationRequest(idpClient: IdPClient) -> ASAuthorizationAppleIDRequest {
        //  Construct Identity Provider instance, and create request
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        //  Parse array of scope strings into ASAuthorization.Scope array
        var requestedScopes: [ASAuthorization.Scope] = []
        for scope in idpClient.scopes ?? [] {
            if (scope == "name" || scope == "fullName") {
                requestedScopes.append(.fullName)
            }
            if (scope == "email") {
                requestedScopes.append(.email)
            }
            FRLog.v("Provided scope (\(scope))")
        }
        request.requestedScopes = requestedScopes
        
        //  Inject nonce if provided
        if let nonce = idpClient.nonce {
            FRLog.v("nonce is received in `IdPClient`, injecting nonce for authorization request")
            request.nonce = nonce
        }
        
        self.acceptsJSON = idpClient.acceptsJSON
        if self.acceptsJSON {
            self.tokenType = "JSON"
        }
        
        return request
    }
}


extension AppleSignInHandler: ASAuthorizationControllerDelegate {
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            FRLog.v("ASAuthorizationAppleIDCredential received: \(appleIDCredential)")
            
            if self.acceptsJSON == true {
                let appleSignInResponse = AppleSignInResponse(appleIDCredential)
                guard let IDToken1tokenJSON = try? JSONEncoder().encode(appleSignInResponse), let IDToken1token = String(data: IDToken1tokenJSON, encoding: .utf8) else {
                    self.completionCallback?(nil, nil, SocialLoginError.unsupportedCredentials("Failed to parse received credentials data (ASAuthorizationAppleIDCredential.identityToken)"))
                    return
                }
                self.completionCallback?(IDToken1token, self.tokenType, nil)
            } else {
                let appleSignInResponse = AppleSignInResponse(appleIDCredential)
                guard let id_token = appleSignInResponse.id_token else {
                    self.completionCallback?(nil, nil, SocialLoginError.unsupportedCredentials("Failed to parse received credentials data (ASAuthorizationAppleIDCredential.identityToken and ASAuthorizationAppleIDCredential.fullName)"))
                    return
                }
                self.completionCallback?(id_token, self.tokenType, nil)
            }
            
            break
        case let passwordCredential as ASPasswordCredential:
            FRLog.v("ASPasswordCredential received: \(passwordCredential)")
            self.completionCallback?(nil, nil, SocialLoginError.unsupportedCredentials("ASPasswordCredential is not supported"))
            break
        default:
            break
        }
    }
    
    
    @available(iOS 13.0, *)
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        FRLog.e("An error occurred during Sign-in With Apple: \(error.localizedDescription)")
        self.completionCallback?(nil, nil, error)
    }
}


extension AppleSignInHandler: ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    @available(iOS 13.0, *)
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
