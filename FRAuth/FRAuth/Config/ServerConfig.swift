//
//  ServerConfig.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Configuration object represents OpenAM, or FRaaS environment information
@objc(FRServerConfig)
public class ServerConfig: NSObject, Codable {
    
    //  MARK: - Property
    
    /// BaseURL of designated server
    @objc let baseURL: URL
    /// Realm of AM Instance for ServerConfig; default value will be 'root'
    @objc let realm: String
    /// Timeout value in second for requests made for ServerConfig object; default value will be 60.0 seconds
    @objc let timeout: Double
    /// Absolute URL string of token endpoint
    @objc let tokenURL: String
    /// Absolute URL string of authorize endpoint
    @objc let authorizeURL: String
    /// Absolute URL string of AuthTree endpoint
    @objc let treeURL: String
    /// Absolute URL string of UserInfo endpoint
    @objc let userInfoURL: String
    /// Absolute URL string of Token Revoke endpoint
    @objc let tokenRevokeURL: String
    /// Absolute URL string of SSO Token logout endpoint
    @objc let ssoTokenLogoutURL: String
    
    
    //  MARK: - Init
    
    /// Constructs ServerConfig instance with URL, realm in OpenAM, and timeout for all requests
    ///
    /// - Parameters:
    ///   - url: Base URL of OpenAM
    ///   - realm: Designated 'realm' to be communicated in OpenAM
    ///   - timeout: Timeout in seconds for all requests
    @objc
    public init (url:URL, realm:String = "root", timeout:Double = 60.0) {
        self.baseURL = url
        self.realm = realm
        self.timeout = timeout
        self.treeURL = self.baseURL.absoluteString + "/json/realms/\(self.realm)/authenticate"
        self.tokenURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/access_token"
        self.authorizeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/authorize"
        self.userInfoURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/userinfo"
        self.tokenRevokeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/token/revoke"
        self.ssoTokenLogoutURL = self.baseURL.absoluteString + "/json/realms/\(self.realm)/sessions"
    }
}
