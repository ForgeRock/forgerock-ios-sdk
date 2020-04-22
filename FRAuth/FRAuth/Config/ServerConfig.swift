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
    @objc var realm: String
    /// Timeout value in second for requests made for ServerConfig object; default value will be 60.0 seconds
    @objc var timeout: Double
    /// Absolute URL string of token endpoint
    @objc var tokenURL: String
    /// Absolute URL string of authorize endpoint
    @objc var authorizeURL: String
    /// Absolute URL string of AuthTree endpoint
    @objc var authenticateURL: String
    /// Absolute URL string of UserInfo endpoint
    @objc var userInfoURL: String
    /// Absolute URL string of Token Revoke endpoint
    @objc var tokenRevokeURL: String
    /// Absolute URL string of session endpoint
    @objc var sessionPath: String
    /// Boolean indicator whether SDK should manage the cookie or not; when it is changed to false, all existing cookies will be removed. **Note** If SDK has not been initialized using (FRAuth.start(), this value will be ignored and not persist cookies.
    @objc var enableCookie: Bool
    
    
    //  MARK: - Init
    
    /// Constructs ServerConfig instance with URL, realm in OpenAM, and timeout for all requests
    ///
    /// - Parameters:
    ///   - url: Base URL of OpenAM
    ///   - realm: Designated 'realm' to be communicated in OpenAM
    ///   - timeout: Timeout in seconds for all requests
    ///   - enableCookie: Boolean value to enable cookie management in SDK's communication to AM. **Note** If SDK has not been initialized using (FRAuth.start(), this value will be ignored and not persist cookies.
    @available(*, deprecated, message: "ServerConfig() has been deprecated; use ServerConfigBuilder instead to construct ServerConfig object.") // Deprecated as of FRAuth: v1.0.3
    @objc
    public init (url: URL, realm: String = "root", timeout: Double = 60.0, enableCookie: Bool = true) {
        self.baseURL = url
        self.realm = realm
        self.timeout = timeout
        self.enableCookie = enableCookie
        self.authenticateURL = self.baseURL.absoluteString + "/json/realms/\(self.realm)/authenticate"
        self.tokenURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/access_token"
        self.authorizeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/authorize"
        self.userInfoURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/userinfo"
        self.tokenRevokeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/token/revoke"
        self.sessionPath = self.baseURL.absoluteString + "/json/realms/\(self.realm)/sessions"
    }
    
    
    /// Constructs ServerConfig instance with URL, realm in OpenAM, and timeout for all requests
    ///
    /// - Parameters:
    ///   - url: Base URL of OpenAM
    ///   - realm: Designated 'realm' to be communicated in OpenAM
    ///   - timeout: Timeout in seconds for all requests
    ///   - enableCookie: Boolean value to enable cookie management in SDK's communication to AM. **Note** If SDK has not been initialized using (FRAuth.start(), this value will be ignored and not persist cookies.
    init(url: URL, realm: String) {
        self.baseURL = url
        self.realm = realm
        self.timeout = 60.0
        self.enableCookie = true
        self.authenticateURL = self.baseURL.absoluteString + "/json/realms/\(self.realm)/authenticate"
        self.tokenURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/access_token"
        self.authorizeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/authorize"
        self.userInfoURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/userinfo"
        self.tokenRevokeURL = self.baseURL.absoluteString + "/oauth2/realms/\(self.realm)/token/revoke"
        self.sessionPath = self.baseURL.absoluteString + "/json/realms/\(self.realm)/sessions"
    }
}


@objc(FRServerConfigBuilder)
public class ServerConfigBuilder: NSObject {
    
    var config: ServerConfig
    
    @objc
    public init(url: URL, realm: String = "root") {
        self.config = ServerConfig(url: url, realm: realm)
    }
    
    @objc
    @discardableResult public func set(timeout: Double) -> ServerConfigBuilder {
        self.config.timeout = timeout
        return self
    }
    
    @objc
    @discardableResult public func set(enableCookie: Bool) -> ServerConfigBuilder {
        self.config.enableCookie = enableCookie
        return self
    }
    
    @objc
    @discardableResult public func set(authenticatePath: String) -> ServerConfigBuilder {
        self.config.authenticateURL = self.config.baseURL.absoluteString + authenticatePath
        return self
    }
    
    @objc
    @discardableResult public func set(tokenPath: String) -> ServerConfigBuilder {
        self.config.tokenURL = self.config.baseURL.absoluteString + tokenPath
        return self
    }
    
    @objc
    @discardableResult public func set(authorizePath: String) -> ServerConfigBuilder {
        self.config.authorizeURL = self.config.baseURL.absoluteString + authorizePath
        return self
    }
    
    @objc
    @discardableResult public func set(userInfoPath: String) -> ServerConfigBuilder {
        self.config.userInfoURL = self.config.baseURL.absoluteString + userInfoPath
        return self
    }
    
    @objc
    @discardableResult public func set(revokePath: String) -> ServerConfigBuilder {
        self.config.tokenRevokeURL = self.config.baseURL.absoluteString + revokePath
        return self
    }
    
    @objc
    @discardableResult public func set(sessionPath: String) -> ServerConfigBuilder {
        self.config.sessionPath = self.config.baseURL.absoluteString + sessionPath
        return self
    }
    
    @objc
    public func build() -> ServerConfig {
        return self.config
    }
}
