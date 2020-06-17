//
//  Config.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

@objc(FRTestConfig)
class Config: NSObject {
    @objc var username: String
    @objc var password: String
    @objc var kba: [String: String]?
    
    @objc var userEmail: String
    @objc var userFirstName: String
    @objc var userLastName: String
    @objc var userInfo: [String: Any]?
    
    @objc var authServiceName: String?
    @objc var registrationServiceName: String?
    
    @objc var configPlistFileName: String?
    
    @objc var oAuth2Client: OAuth2Client?
    @objc var serverConfig: ServerConfig?
    
    var keychainManager: KeychainManager?
    var sessionManager: SessionManager?
    var tokenManager: TokenManager?
    
    @objc var configJSON: [String: Any]?
    
    override init() {
        self.username = "test_username"
        self.password = "test_password"
        self.userEmail = "test@test.com"
        self.userFirstName = "TestFirst"
        self.userLastName = "TestLast"
    }
    
    @objc
    init(_ configFileName: String) throws {
        
        self.username = ""
        self.password = ""
        self.userLastName = ""
        self.userFirstName = ""
        self.userEmail = ""
        
        if let path = Bundle(for: FRBaseTest.self).path(forResource: configFileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let config = jsonResult as? [String: Any] {
                    self.configJSON = config
                    guard let username = config["username"] as? String,
                        let password = config["password"] as? String,
                        let email = config["user-email"] as? String,
                        let firstName = config["user-first-name"] as? String,
                        let lastName = config["user-last-name"] as? String,
                        let kba = config["kba"] as? [String: String] else {
                        throw ConfigError.invalidConfiguration("Test config data is empty or invalid")
                    }
                    
                    self.username = username
                    self.password = password
                    self.userEmail = email
                    self.userFirstName = firstName
                    self.userLastName = lastName
                    self.kba = kba
                    
                    if let userInfo = config["user-info"] as? [String: Any] {
                        self.userInfo = userInfo
                    }
                    
                    if let configPlistFileName = config["configPlistFileName"] as? String {
                        self.configPlistFileName = configPlistFileName
                        FRAuth.configPlistFileName = configPlistFileName
                    }
                    else if let urlString = config["forgerock_url"] as? String, let url = URL(string: urlString), let timeout = config["forgerock_timeout"] as? Double, let authServiceName = config["forgerock_auth_service_name"] as? String, let registrationServiceName = config["forgerock_registration_service_name"] as? String, let oauthClientId = config["forgerock_oauth_client_id"] as? String, let redirectUriStr = config["forgerock_oauth_redirect_uri"] as? String, let redirectUri = URL(string: redirectUriStr), let scope = config["forgerock_oauth_scope"] as? String, let threshold = config["forgerock_oauth_threshold"] as? Int, let realm = config["forgerock_realm"] as? String {
                        
                        self.authServiceName = authServiceName
                        self.registrationServiceName = registrationServiceName
                        
                        let enableCookie = config["forgerock_enable_cookie"] as? Bool ?? true
                        
                        let serverConfig = ServerConfig(url: url, realm: realm, timeout: timeout, enableCookie: enableCookie)
                        let oAuth2Client = OAuth2Client(clientId: oauthClientId, scope: scope, redirectUri: redirectUri, serverConfig: serverConfig, threshold: threshold)
                        self.serverConfig = serverConfig
                        self.oAuth2Client = oAuth2Client
                        
                        if let accessGroup = config["forgerock_keychain_access_group"] as? String, let keychainManager = try KeychainManager(baseUrl:url.absoluteString + "/" + realm, accessGroup: accessGroup) {
                            let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                            let tokenManager = TokenManager(oAuth2Client: oAuth2Client, sessionManager: sessionManager)
                            self.keychainManager = keychainManager
                            self.sessionManager = sessionManager
                            self.tokenManager = tokenManager
                        }
                        else if let keychainManager = try KeychainManager(baseUrl:url.absoluteString + "/" + realm) {
                            let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                            let tokenManager = TokenManager(oAuth2Client: oAuth2Client, sessionManager: sessionManager)
                            self.keychainManager = keychainManager
                            self.sessionManager = sessionManager
                            self.tokenManager = tokenManager
                        }
                    }
                    else {
                        throw ConfigError.invalidConfiguration("\(configFileName) is invalid or missing some value")
                    }
                }
            } catch {
                throw error
            }
        }
        else {
            throw ConfigError.emptyConfiguration
        }
    }
}
