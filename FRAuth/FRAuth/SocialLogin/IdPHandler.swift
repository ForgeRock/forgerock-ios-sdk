// 
//  IdPHandler.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit


/**
 IdPHandler is a protocol for `IdPHandler` implementation and is responsible to perform sign-in / authorization process against given Social Identity Provider defined in AM
 */
public protocol IdPHandler {
    
    /// String value for type of credentials that `IdPHandler` is obtaining and sending to AM; available values: `authorization_code`, `access_token`, and `id_token`
    var tokenType: String { get }
    
    /// Optional `UIViewController` that is currently presented in the application
    var presentingViewController: UIViewController? { get set }
    
    /// Signs-in a user against selected Identity Provider with `IdPClient` information, and sends received credentials from providers to AM
    /// - Parameters:
    ///   - idpClient: `IdPClient` that contains Social Identity Provider's OAuth2 / OIDC client information to perform social login
    ///   - completion: Completion callback to notify the result
    func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback)
    
    /// Returns `UIView` of button that is rendered and generated from the provider's SDK
    func getProviderButtonView() -> UIView?
}
