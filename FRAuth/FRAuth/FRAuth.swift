//
//  FRAuth.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// Enumeration for available auth type through FRAuth
///
/// - authentication: Auth type for authentication or user login
/// - registration: Auth type for user registration
@objc public enum FRAuthFlowType: Int {
    case authentication
    case registration
}


/**
 FRAuth is an abstraction of authentication and/or registration with OpenAM through FRAuth SDK.
 
 ## Note ##
    * In order to use abstraction layer of FRAuth SDK, you **must** initiate SDK using *FRAuth.start()*. Upon completion of SDK initialization, object models (FRDevice and/or FRUser) become available.
    * For SDK initialization, you must have proper configuration file as in .plist; default .plist that FRAuth SDK looks for is 'FRAuthConfig.plist', and the config file name can be changed through *FRAuth.configPlistFileName* property.
 */
@objc
public final class FRAuth: NSObject {
    
    //  MARK: - Property
    
    /// Configuration .plist file name; defaulted to 'FRAuthConfig'
    @objc
    public static var configPlistFileName: String = "FRAuthConfig"
    /// Shared instance of FRAuth
    @objc
    public static var shared: FRAuth? = nil
    /// AuthServiceName; AuthTree name for user authentication
    var authServiceName: String
    /// RegisterServiceNAme; AuthTree name for user registration
    var registerServiceName: String
    /// ServerConfig instance for FRAuth; ServerConfig values are retrieved from .plist configuration file
    var serverConfig: ServerConfig
    /// OAuth2Client instance for FRAuth; OAuth2Client values are retrieved from .plist configuration file
    var oAuth2Client: OAuth2Client?
    /// TokenManager instance for FRAuth to perform any token related operation
    var tokenManager: TokenManager?
    /// SessionManager instance for FRAuth to perform manage, and persist session
    var sessionManager: SessionManager
    /// KeychainManager instance for FRAuth to perform any keychain related operation to persist and/or retrieve credentials
    var keychainManager: KeychainManager
    
    func getServiceName() -> String {
        return self.authServiceName
    }
    
    //  MARK: - Init
    
    /// Initializes SDK using .plist configuration file
    ///
    /// - Throws: ConfigError when invalid or missing value in .plist configuration file
    @objc static public func start() throws {
        guard let path = Bundle.main.path(forResource: configPlistFileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist")
            throw ConfigError.emptyConfiguration
        }
        FRLog.i("SDK is initializing: \(configPlistFileName).plist")
        FRLog.v("\(configPlistFileName).plist : \(config)")
        try FRAuth.initPrivate(config: config)
        
        if let c: NSObject.Type = NSClassFromString("FRProximity.FRProximity") as? NSObject.Type{
            FRLog.i("FRProximity SDK found; starting FRProximity")
            c.perform(Selector(("startProximity")))
        }
    }
    
    //  MARK: - Private Init
    
    /// Initializes FRAuth shared instance with Configuration values as Dictionary
    ///
    /// - Parameter config: Dictionary object of configuration
    /// - Throws: ConfigError
    static func initPrivate(config: [String: Any]) throws {
        
        // Validate server config
        guard let server = config["forgerock_url"] as? String,
            let serverUrl = URL(string: server),
            serverUrl.absoluteString.isValidUrl else {
                let errorMsg = "server config (forgerock_url) is empty"
                FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist. \(errorMsg)")
                throw ConfigError.invalidConfiguration(errorMsg)
        }
        
        // Check if realm value is in config
        var realm = "root"
        if let realmConfig = config["forgerock_realm"] as? String {
            realm = realmConfig
        }
        
        // ServerConfig builder
        let configBuilder = ServerConfigBuilder(url: serverUrl, realm: realm)
        
        // ServerConfig building with config values
        if let enableCookieConfig = config["forgerock_enable_cookie"] as? Bool {
            configBuilder.set(enableCookie: enableCookieConfig)
        }
        
        if let cookieName = config["forgerock_cookie_name"] as? String {
            configBuilder.set(cookieName: cookieName)
        }
        
        if let timeOutConfigStr = config["forgerock_timeout"] as? String, let timeOutConfigDouble = Double(timeOutConfigStr) {
            configBuilder.set(timeout: timeOutConfigDouble)
        }
        
        if let authenticatePath = config["forgerock_authenticate_endpoint"] as? String {
            configBuilder.set(authenticatePath: authenticatePath)
        }
        
        if let authorizePath = config["forgerock_authorize_endpoint"] as? String {
            configBuilder.set(authorizePath: authorizePath)
        }
        
        if let tokenPath = config["forgerock_token_endpoint"] as? String {
            configBuilder.set(tokenPath: tokenPath)
        }
        
        if let revokePath = config["forgerock_revoke_endpoint"] as? String {
            configBuilder.set(revokePath: revokePath)
        }
        
        if let userInfoPath = config["forgerock_userinfo_endpoint"] as? String {
            configBuilder.set(userInfoPath: userInfoPath)
        }
        
        if let sessionPath = config["forgerock_session_endpoint"] as? String {
            configBuilder.set(sessionPath: sessionPath)
        }
        
        // Validate Auth/Registration Service
        guard let authServiceName = config["forgerock_auth_service_name"] as? String else {
            let errorMsg = "forgerock_auth_service_name is empty"
            FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist. \(errorMsg)")
            throw ConfigError.invalidConfiguration(errorMsg)
        }
        
        let registrationServiceName = config["forgerock_registration_service_name"] as? String ?? ""
        
        var threshold = 60
        if let thresholdConfigStr = config["forgerock_oauth_threshold"] as? String, let timeOutConfigInt = Int(thresholdConfigStr) {
            threshold = timeOutConfigInt
        }
        
        let serverConfig = configBuilder.build()
        FRLog.v("ServerConfig created: \(serverConfig)")
        var oAuth2Client: OAuth2Client?
        
        if let clientId = config["forgerock_oauth_client_id"] as? String,
        let redirectUriAsString = config["forgerock_oauth_redirect_uri"] as? String,
        let redirectUri = URL(string: redirectUriAsString),
        redirectUri.absoluteString.isValidUrl,
        let scope = config["forgerock_oauth_scope"] as? String
        {
            oAuth2Client = OAuth2Client(clientId: clientId, scope: scope, redirectUri: redirectUri, serverConfig: serverConfig, threshold: threshold)
            FRLog.v("OAuth2Client created: \(String(describing: oAuth2Client))")
        }
        else {
            FRLog.w("Failed to load OAuth2 configuration; continue on SDK initialization without OAuth2 module.")
        }
                
        if let accessGroup = config["forgerock_keychain_access_group"] as? String {
            if let keychainManager = try KeychainManager(baseUrl: serverUrl.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup) {
                keychainManager.validateEncryption()
                let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                var tokenManager: TokenManager?
                if let oAuth2Client = oAuth2Client {
                    tokenManager = TokenManager(oAuth2Client: oAuth2Client, keychainManager: keychainManager)
                }
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
        }
        else {
            if let keychainManager = try KeychainManager(baseUrl: serverUrl.absoluteString + "/" + serverConfig.realm) {
                keychainManager.validateEncryption()
                let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                var tokenManager: TokenManager?
                if let oAuth2Client = oAuth2Client {
                    tokenManager = TokenManager(oAuth2Client: oAuth2Client, keychainManager: keychainManager)
                }
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
        }
    }
    
    
    /// Initializes FRAuth shared instance with required instances
    ///
    /// - Parameters:
    ///   - authServiceName: AuthTree name for authentication
    ///   - registerServiceName: AuthTree name for registration
    ///   - serverConfig: ServerConfig instance
    ///   - oAuth2Client: OAuth2Client instance
    ///   - tokenManager: TokenMAnager instance
    ///   - keychainManager: KeychainManager instance
    ///   - sessionManager: SessionManager instance
    init(authServiceName: String, registerServiceName: String, serverConfig: ServerConfig, oAuth2Client: OAuth2Client?, tokenManager: TokenManager?, keychainManager: KeychainManager, sessionManager: SessionManager) {
        
        FRLog.i("SDK initialized", false)
        
        self.authServiceName = authServiceName
        self.registerServiceName = registerServiceName
        self.serverConfig = serverConfig
        self.oAuth2Client = oAuth2Client
        self.tokenManager = tokenManager
        self.keychainManager = keychainManager
        self.sessionManager = sessionManager
        
        super.init()
    }
    
    
    // - MARK: Private
    
    /// Initiates Authentication Tree with `suspendedId`
    /// - Parameters:
    ///   - suspendedId: suspendedId contained in resumeURI contained in Email received from `Email Suspend Node` in AM
    ///   - completion: NodeCompletion callback which returns the result of Node submission
    func next<T>(suspendedId: String, completion: @escaping NodeCompletion<T>) {
        let authService: AuthService = AuthService(suspendedId: suspendedId, serverConfig: self.serverConfig, oAuth2Config: self.oAuth2Client, keychainManager: self.keychainManager, tokenManager: self.tokenManager)
        authService.next { (value: T?, node, error) in
            completion(value, node, error)
        }
    }
    
        
    /// Initiates Authentication Tree with specified authIndexValue and authIndexType.
    /// - Parameter authIndexValue: authIndexValue; Authentication Tree name value in String
    /// - Parameter authIndexType: authIndexType: Authentication Tree type value in String
    /// - Parameter completion:NodeCompletion callback which returns the result of Node submission
    func next<T>(authIndexValue: String, authIndexType: String, completion: @escaping NodeCompletion<T>) {
        
        let authService: AuthService = AuthService(authIndexValue: authIndexValue, serverConfig: self.serverConfig, oAuth2Config: self.oAuth2Client, keychainManager: self.keychainManager, tokenManager: self.tokenManager, authIndexType: authIndexType)
        authService.next { (value: T?, node, error) in
            completion(value, node, error)
        }
    }
}
