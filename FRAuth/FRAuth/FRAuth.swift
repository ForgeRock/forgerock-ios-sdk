//
//  FRAuth.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
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
        
        for bundle in Bundle.allFrameworks {
            if bundle.bundleIdentifier == "com.forgerock.ios.FRProximity" || bundle.bundleIdentifier == "org.cocoapods.FRProximity" {
                if let c: NSObject.Type = NSClassFromString("FRProximity.FRProximity") as? NSObject.Type{
                    FRLog.i("FRProximity SDK found; starting FRProximity")
                    c.perform(Selector(("startProximity")))
                }
            }
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
        
        // Validate Auth/Registration Service
        guard let authServiceName = config["forgerock_auth_service_name"] as? String else {
            let errorMsg = "forgerock_auth_service_name is empty"
            FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist. \(errorMsg)")
            throw ConfigError.invalidConfiguration(errorMsg)
        }
        
        let registrationServiceName = config["forgerock_registration_service_name"] as? String ?? ""
        
        // Check if realm value is in config, otherwise, configure with default
        var realm = "root"
        if let realmConfig = config["forgerock_realm"] as? String {
            realm = realmConfig
        }
        
        // Check if timeout value is in config, otherwise, configure with default
        var timeout = 60.0
        if let timeOutConfigStr = config["forgerock_timeout"] as? String, let timeOutConfigDouble = Double(timeOutConfigStr) {
            timeout = timeOutConfigDouble
        }
        
        var threshold = 60
        if let thresholdConfigStr = config["forgerock_oauth_threshold"] as? String, let timeOutConfigInt = Int(thresholdConfigStr) {
            threshold = timeOutConfigInt
        }
        
        let serverConfig = ServerConfig(url: serverUrl, realm: realm, timeout: timeout)
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
            if let keychainManager = try KeychainManager(baseUrl: serverUrl.absoluteString + "/" + realm, accessGroup: accessGroup) {
                
                let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                var tokenManager: TokenManager?
                if let oAuth2Client = oAuth2Client {
                    tokenManager = TokenManager(oAuth2Client: oAuth2Client, sessionManager: sessionManager)
                }
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
        }
        else {
            if let keychainManager = try KeychainManager(baseUrl: serverUrl.absoluteString + "/" + realm) {
                
                let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                var tokenManager: TokenManager?
                if let oAuth2Client = oAuth2Client {
                    tokenManager = TokenManager(oAuth2Client: oAuth2Client, sessionManager: sessionManager)
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
        
        FRLog.i("SDK initializaed", false)
        
        self.authServiceName = authServiceName
        self.registerServiceName = registerServiceName
        self.serverConfig = serverConfig
        self.oAuth2Client = oAuth2Client
        self.tokenManager = tokenManager
        self.keychainManager = keychainManager
        self.sessionManager = sessionManager
        
        super.init()
    }
    
    
    // - MARK: Public
    
    /// Initiates Authentication or Registration flow with given flowType and expected result type
    ///
    /// - Parameters:
    ///   - flowType: FlowType whether authentication, or registration
    ///   - completion: NodeCompletion callback which returns the result of Node submission.
    public func next<T>(flowType: FRAuthFlowType, completion:@escaping NodeCompletion<T>) {
        FRLog.v("Called")
        
        var serviceName = ""
        switch flowType {
        case .authentication:
            serviceName = self.authServiceName
            break
        case .registration:
            serviceName = self.registerServiceName
            break
        }
        
        let authService: AuthService = AuthService(name: serviceName, serverConfig: self.serverConfig, oAuth2Config: self.oAuth2Client, sessionManager: self.sessionManager)
        authService.next { (value: T?, node, error) in
            completion(value, node, error)
        }
    }
    
    
    //  MARK: - Objective-C Compatibility
    
    @objc(nextWithFlowType:tokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithFlowType(flowType: FRAuthFlowType, completion:@escaping NodeCompletion<Token>) {
        FRLog.v("Called")
        self.next(flowType: flowType) { (token: Token?, node, error) in
            completion(token, node, error)
        }
    }
    

    @objc(nextWithFlowType:accessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithFlowType(flowType: FRAuthFlowType, completion:@escaping NodeCompletion<AccessToken>) {
        FRLog.v("Called")
        self.next(flowType: flowType) { (token: AccessToken?, node, error) in
            completion(token, node, error)
        }
    }
    
    
    @objc(nextWithFlowType:userCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithFlowType(flowType: FRAuthFlowType, completion:@escaping NodeCompletion<FRUser>) {
        FRLog.v("Called")
        self.next(flowType: flowType) { (user: FRUser?, node, error) in
            completion(user, node, error)
        }
    }
}
