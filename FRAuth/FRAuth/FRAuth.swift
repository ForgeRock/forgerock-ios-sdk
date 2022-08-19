//
//  FRAuth.swift
//  FRAuth
//
//  Copyright (c) 2019-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

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
    * For SDK initialization, you must have proper configuration file as in .plist; default .plist that FRAuth SDK looks for is 'FRAuthConfig.plist', and the config file name can be changed through *FRAuth.configPlistFileName* property, or create an FROptions object and pass it in the *FRAuth.start(options: FROptions? = nil)* "options" parameter.
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
    
    public var options: FROptions? = nil
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
    /// - Parameter options: Optional FROptions object. This will contain the configuration if programmatically initialised. The default value in nil to ensure backwards compatibility. If an FROptions object is passed the configuration plist will be ignored
    /// - Throws: ConfigError when invalid or missing value in .plist configuration file
    @objc static public func start(options: FROptions? = nil) throws {
        if let frOptions = options {
            let config = try frOptions.asDictionary()
            FRLog.i("SDK is initializing with FROptions")
            FRLog.v("FROptions: \(config)")
            try FRAuth.initPrivate(config: config)
            FRAuth.shared?.options = options
        } else {
            FRAuth.shared?.options = nil
            guard let path = Bundle.main.path(forResource: configPlistFileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
                FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist")
                throw ConfigError.emptyConfiguration
            }
            FRLog.i("SDK is initializing: \(configPlistFileName).plist")
            FRLog.v("\(configPlistFileName).plist : \(config)")
            try FRAuth.initPrivate(config: config)
            FRAuth.shared?.options = FROptions(config: config)
        }
        
        if let c: NSObject.Type = NSClassFromString("FRProximity.FRProximity") as? NSObject.Type {
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
        
        // Check if there is an existing session and destroy it, do a clean up as this would only happen at this point
        // if the SDK has been previously initialized and a succesfull authentication has happened. Given that the SDK gets
        // re-initiallised, possibly with a different configuration we need to do some clean up.
        if let _ = FRUser.currentUser {
            FRAuth.cleanUp()
        }
        
        // Validate server config
        guard let server = config[FROptions.CodingKeys.url.rawValue] as? String,
            let serverUrl = URL(string: server),
            serverUrl.absoluteString.isValidUrl else {
                let errorMsg = "server config (forgerock_url) is empty"
                FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist. \(errorMsg)")
                throw ConfigError.invalidConfiguration(errorMsg)
        }
        
        // Check if realm value is in config
        var realm = "root"
        if let realmConfig = config[FROptions.CodingKeys.realm.rawValue] as? String {
            realm = realmConfig
        }
        
        // ServerConfig builder
        let configBuilder = ServerConfigBuilder(url: serverUrl, realm: realm)
        
        // ServerConfig building with config values
        if let enableCookieConfig = config[FROptions.CodingKeys.enableCookie.rawValue] as? Bool {
            configBuilder.set(enableCookie: enableCookieConfig)
        }
        
        if let cookieName = config[FROptions.CodingKeys.cookieName.rawValue] as? String {
            configBuilder.set(cookieName: cookieName)
        }
        
        if let timeOutConfigStr = config[FROptions.CodingKeys.timeout.rawValue] as? String, let timeOutConfigDouble = Double(timeOutConfigStr) {
            configBuilder.set(timeout: timeOutConfigDouble)
        }
        
        if let authenticatePath = config[FROptions.CodingKeys.authenticateEndpoint.rawValue] as? String {
            configBuilder.set(authenticatePath: authenticatePath)
        }
        
        if let authorizePath = config[FROptions.CodingKeys.authorizeEndpoint.rawValue] as? String {
            configBuilder.set(authorizePath: authorizePath)
        }
        
        if let tokenPath = config[FROptions.CodingKeys.tokenEndpoint.rawValue] as? String {
            configBuilder.set(tokenPath: tokenPath)
        }
        
        if let revokePath = config[FROptions.CodingKeys.revokeEndpoint.rawValue] as? String {
            configBuilder.set(revokePath: revokePath)
        }
        
        if let userInfoPath = config[FROptions.CodingKeys.userinfoEndpoint.rawValue] as? String {
            configBuilder.set(userInfoPath: userInfoPath)
        }
        
        if let sessionPath = config[FROptions.CodingKeys.sessionEndpoint.rawValue] as? String {
            configBuilder.set(sessionPath: sessionPath)
        }
        
        if let endSessionPath = config[FROptions.CodingKeys.endSessionEndpoint.rawValue] as? String {
            configBuilder.set(endSessionPath: endSessionPath)
        }
        
        // Validate Auth/Registration Service
        guard let authServiceName = config[FROptions.CodingKeys.authServiceName.rawValue] as? String else {
            let errorMsg = "forgerock_auth_service_name is empty"
            FRLog.e("Failed to load configuration file; abort SDK initialization: \(configPlistFileName).plist. \(errorMsg)")
            throw ConfigError.invalidConfiguration(errorMsg)
        }
        
        let registrationServiceName = config[FROptions.CodingKeys.registrationServiceName.rawValue] as? String ?? ""
        
        var threshold = 60
        if let thresholdConfigStr = config[FROptions.CodingKeys.oauthThreshold.rawValue] as? String, let timeOutConfigInt = Int(thresholdConfigStr) {
            threshold = timeOutConfigInt
        }
        
        let serverConfig = configBuilder.build()
        FRLog.v("ServerConfig created: \(serverConfig)")
        var oAuth2Client: OAuth2Client?
        
        if let clientId = config[FROptions.CodingKeys.oauthClientId.rawValue] as? String,
        let redirectUriAsString = config[FROptions.CodingKeys.oauthRedirectUri.rawValue] as? String,
        let redirectUri = URL(string: redirectUriAsString),
        redirectUri.absoluteString.isValidUrl,
        let scope = config[FROptions.CodingKeys.oauthScope.rawValue] as? String
        {
            oAuth2Client = OAuth2Client(clientId: clientId, scope: scope, redirectUri: redirectUri, serverConfig: serverConfig, threshold: threshold)
            FRLog.v("OAuth2Client created: \(String(describing: oAuth2Client))")
        }
        else {
            FRLog.w("Failed to load OAuth2 configuration; continue on SDK initialization without OAuth2 module.")
        }
                
        if let accessGroup = config[FROptions.CodingKeys.keychainAccessGroup.rawValue] as? String {
            if let keychainManager = try KeychainManager(baseUrl: serverUrl.absoluteString + "/" + serverConfig.realm, accessGroup: accessGroup) {
                keychainManager.validateEncryption()
                let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
                var tokenManager: TokenManager?
                if let oAuth2Client = oAuth2Client {
                    tokenManager = TokenManager(oAuth2Client: oAuth2Client, keychainManager: keychainManager)
                } else {
                    let _ = try? keychainManager.setAccessToken(token: nil)
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
                } else {
                    let _ = try? keychainManager.setAccessToken(token: nil)
                }
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
        }
        
        //Look for provided SSL Pinning key hashes. If present, enable default SSL pinning for the FRCore RestClient.
        // Step 1: create a FRSecurityConfiguration with the provided hashes
        // Step 2: create a FRURLSessionSSLPinningHandler with the FRSecurityConfiguration
        // Step 3: pass the FRURLSessionSSLPinningHandler to the FRCore RestClient. This will be used for all communication via the SDK
        // Customization: If developers want to customise the default implementation they would need to override
        // the FRURLSessionHandler class and provide their own implementation. The new handler would need to be set in the
        // RestClient setURLSessionConfiguration(config: URLSessionConfiguration?, handler: URLSessionDelegate?) method.
        if let forgerockPKHashes = config[FROptions.CodingKeys.sslPinningPublicKeyHashes.rawValue] as? [String], !forgerockPKHashes.isEmpty {
            let frSecurityConfiguration = FRSecurityConfiguration(hashes: forgerockPKHashes)
            let pinningHanlder = FRURLSessionSSLPinningHandler(frSecurityConfiguration: frSecurityConfiguration)
            RestClient.shared.setURLSessionConfiguration(config: nil, handler: pinningHanlder)
        } else {
            // This will set the default SDK configuration for the RestClient
            RestClient.shared.setURLSessionConfiguration(config: nil, handler: nil)
        }
        
        if let optionData = FRAuth.shared?.keychainManager.getFROptions() {
            let decoder = JSONDecoder()
            let currentOptions = FROptions(config: config)
            if let options = try? decoder.decode(FROptions.self, from: optionData) {
                if !(currentOptions == options)  {
                    //New configuration does not match the old config used. Clean up the keychain and revoke the tokens if possible.
                    FRAuth.cleanUp()
                }
            }
        }
        
        //Save the configuration used.
        let encoder = JSONEncoder()
        let options = FROptions(config: config)
        if let optionsData = try? encoder.encode(options) {
            FRAuth.shared?.keychainManager.setFROptions(frOptionsData: optionsData)
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
    
    static func cleanUp() {
        if let currentUser = FRUser.currentUser {
            currentUser.logout()
        } else {
            //If the session manager exists already revoke the Session Token.
            if let sessionManager = FRAuth.shared?.sessionManager {
                sessionManager.revokeSSOToken()
            }
        }
    }
}
