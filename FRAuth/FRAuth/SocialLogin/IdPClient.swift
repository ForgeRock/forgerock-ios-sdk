// 
//  IdPClient.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 IdPClient is a representation of OAuth2 / OIDC client information to perfrom social login against selected provider
 */
public struct IdPClient {
    /// Provider identifier value defined for selected Social Identity Provider from AM
    public let provider: String
    /// Client identifier value defined for selected Social Identity Provider from AM
    public let clientId: String
    /// Redirect URI value defined for selected Social Identity Provider from AM
    public let redirectUri: String
    /// An array of scope values in array for selected Social Identity Provider from AM
    public let scopes: [String]?
    /// Optional nonce string value for selected Social Identity Provider from AM
    public let nonce: String?
    /// An array of ACR values for selected Social Identity Provider from AM
    public let acrValues: [String]?
    /// Request string value for selected Social Identity Provider from AM
    public let request: String?
    /// Request URI value for selected Social Identity Provider from AM
    public let requestUri: String?
}
