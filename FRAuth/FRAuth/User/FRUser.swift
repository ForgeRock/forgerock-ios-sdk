//
//  FRUser.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// FRUser represents authenticated user session as FRUser object
@objc
public class FRUser: NSObject, NSSecureCoding {

    //  MARK: - Properties
    
    /**
     Singleton instance represents currently authenticated user.
     
     ## Note ##
     If SDK has not been started using *FRAuth.start()*, *FRUser.currentUser* returns nil even if user session has previously authenticated, and valid.
     */
    @objc
    public static var currentUser: FRUser? {
        get {
            if let staticUser = _staticUser {
                return staticUser
            }
            else if let frAuth = FRAuth.shared {
                FRLog.v("FRUser retrieved from SessionManager")
                _staticUser = frAuth.sessionManager.getCurrentUser()
                return _staticUser
            }
            
            FRLog.w("Invalid SDK State: FRUser is returning 'nil'.")
            return nil
        }
    }
    /// static property of current user
    static var _staticUser: FRUser? = nil
    /// AccessToken object associated with FRUser object
    @objc
    public var token: AccessToken?
    /// ServerConfig instance of FRUser
    var serverConfig: ServerConfig
    
    
    //  MARK: - Init
    
    /// Initializes FRUser object with AccessToken, ServerConfig, and UserInfo (optional)
    ///
    /// - Parameters:
    ///   - token: AccessToken object associated with the user instance
    ///   - serverConfig: ServerConfig object associated with the user instance
    init(token: AccessToken?, serverConfig: ServerConfig) {
        
        if let token = token {
            self.token = token
        }
        else if let frAuth = FRAuth.shared {
            self.token = try? frAuth.tokenManager.retrieveAccessTokenFromKeychain()
        }
        
        self.serverConfig = serverConfig
        super.init()
    }
    
    
    //  MARK: - Login
    
    /// Logs-in user based on configuration value initialized through FRAuth.start()
    ///
    /// - NOTE: FRAuth.start() must be called prior to call login
    ///
    /// - Parameter completion: Completion callback which returns FRUser instance (also accessible through FRUser.currentUser), and/or any error encountered during authentication
    @objc
    public static func login(completion:@escaping NodeCompletion<FRUser>) {
        
        if let staticUser = _staticUser {
            FRLog.v("FRUser is already logged-in; returning current user")
            completion(staticUser, nil, nil)
        }
        else if let frAuth = FRAuth.shared {
            FRLog.v("Initiating login process")
            frAuth.next(flowType: .authentication) { (user: FRUser?, node, error) in
                completion(user, node, error)
            }
        }
        else {
            FRLog.w("Invalid SDK State")
            completion(nil, nil, ConfigError.invalidSDKState)
        }
    }
    
    
    //  MARK: - Register
    
    /// Registers a user based on configuration value initialized through FRAuth.start()
    ///
    /// - Parameter completion: Completion callback which returns FRUser instance (also accessible through FRUser.currentUser), and/or any error encountered during registration
    @objc public static func register(completion:@escaping NodeCompletion<FRUser>) {
        
        if let statUser = _staticUser {
            FRLog.v("FRUser is already logged-in; returning current user")
            completion(statUser, nil, nil)
        }
        else if let frAuth = FRAuth.shared {
            FRLog.v("Initiating register process")
            frAuth.next(flowType: .registration) { (user: FRUser?, node, error) in
                completion(user, node, error)
            }
        }
        else {
            FRLog.w("Invalid SDK State")
            completion(nil, nil, ConfigError.invalidSDKState)
        }
    }
    
    //  MARK: - Logout
    
    /// Logs-out currently authenticated user session
    ///
    /// - NOTE: logout method invokes 2 APIs to invalidate user's session: 1) invokes /sessions/?_action=logout to invalidate SSO Token, 2) /token/revoke to invalidate access_token and/or refresh_token (if refresh_token was granted)
    ///
    @objc
    public func logout() {
    
        if let frAuth = FRAuth.shared {
            
            if let ssoToken = frAuth.sessionManager.getSSOToken() {
                FRLog.v("Invalidating SSO Token")
                var parameter: [String: String] = [:]
                parameter[OpenAM.tokenId] = ssoToken.value
                var header: [String: String] = [:]
                header[OpenAM.iPlanetDirectoryPro] = ssoToken.value
                header[OpenAM.acceptAPIVersion] = OpenAM.apiResource31
                var urlParam: [String: String] = [:]
                urlParam[OpenAM.action] = OpenAM.logout
                
                let request = Request(url: self.serverConfig.ssoTokenLogoutURL, method: .POST, headers: header, bodyParams: parameter, urlParams: urlParam, requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
                RestClient.shared.invoke(request: request) { (result) in
                    switch result {
                    case .success( _, _ ):
                        break
                    case .failure(_):
                        break
                    }
                }
            }
            else {
                FRLog.w("No SSO Token found")
            }
            
            guard let token = self.token else {
                self.clearUserSession()
                return
            }
            
            let completionBlock: CompletionCallback = { (error) in
                if let error = error {
                    FRLog.w("Error while invalidating OAuth2 token(s)")
                    if let nsError = error as NSError? {
                        FRLog.w("[\(nsError.domain) - \(nsError.code): \(nsError.localizedDescription)\n\t\(nsError.userInfo)]")
                    }
                }
                else {
                    FRLog.v("Invalidating OAuth2 token(s) successful")
                }
            }
            
            FRLog.v("Invalidating OAuth2 token(s) with \(token.refreshToken != nil ? "refresh_token" : "access_token")")
            frAuth.oAuth2Client.revoke(accessToken: token, completion: completionBlock)
            
            self.clearUserSession()
        }
        else {
            FRLog.w("Invalid SDK state")
        }
    }
    
    
    //  MARK: - AccessToken
    
    /// Retrieves access_token from Keychain storage, and if current access_token is expired, then consumes refresh_token to refresh access_token, and returns FRUser with newly granted access_token
    ///
    /// - Parameter completion: Completion block which returns newly refreshed FRUser object
    @objc
    public func getAccessToken(completion:@escaping UserCallback) {
        if let frAuth = FRAuth.shared {
            frAuth.tokenManager.getAccessToken { (token, error) in
                if let token = token {
                    self.token = token
                    self.save()
                    completion(self, nil)
                }
                else {
                    completion(nil, error)
                }
            }
        }
        else {
            FRLog.w("Invalid SDK state")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Retrieves AccessToken from Keychain storage, and if current AccessToken is about to expire, then consumes refresh_token to refresh AccessToken, and returns FRUser with newly granted AccessToken
    ///
    /// - NOTE: This method performs sync network requests; be careful on calling this method in UI Thread
    ///
    /// - Returns: Updated FRUser object instance with newly granted Accesstoken
    /// - Throws: ConfigError / TokenError / AuthError
    @objc
    public func getAccessToken() throws -> FRUser {
        if let frAuth = FRAuth.shared {
            if let token = try frAuth.tokenManager.getAccessToken() {
                self.token = token
                self.save()
                
                return self
            }
            else {
                throw TokenError.nullToken
            }
        }
        else {
            FRLog.w("Invalid SDK state")
            throw ConfigError.invalidSDKState
        }
    }
    
    
    //  MARK: - UserInfo
    
    /// Retrieves currently authenticated user's UserInfo from /userinfo endpoint
    ///
    /// - Parameter completion: Callback block which returns UserInfo object; UserInfo result is also updated to calling FRUser object instance
    @objc
    public func getUserInfo(completion: @escaping UserInfoCallback) {
        FRLog.v("Requesting UserInfo")
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        header[OAuth2.authorization] = self.buildAuthHeader()
        
        let request = Request(url: self.serverConfig.userInfoURL, method: .GET, headers: header, bodyParams: [:], urlParams: [:], requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
        
        let result = RestClient.shared.invokeSync(request: request)
        
        switch result {
        case .success(let response, _ ):
            completion(UserInfo(response), nil)
        case .failure(let error):
            completion(nil, error)
        }
    }
    
    
    //  MARK: - Authorization Header
    
    /// Builds Authorization header value with currently given access_token
    ///
    /// - Returns: String value for Authorization header in "TOKEN_TYPE ACCESS_TOKEN" format
    @objc
    public func buildAuthHeader() -> String {
        guard let token = self.token else {
            FRLog.w("No access_token found for building Authorization Header")
            return ""
        }
        return token.buildAuthorizationHeader()
    }
    
    
    // MARK: - Private methods
    
    /// Refreshes User's session with refres_token regardless of validity of current access_token
    ///
    /// - Parameter completion: Completion callback that notifies the result of operation
    func refresh(completion:@escaping UserCallback) {
        if let frAuth = FRAuth.shared {
            frAuth.tokenManager.refresh{ (token, error) in
                if let token = token {
                    self.token = token
                    self.save()
                    completion(self, nil)
                }
                else {
                    completion(nil, error)
                }
            }
        }
        else {
            FRLog.w("Invalid SDK state")
            completion(nil, ConfigError.invalidSDKState)
        }
    }
    
    
    /// Clears currently authenticated user instance from Keychain; this invalidates FRUser.currentUser, and FRUser.currentUser returns nil after calling this method
    func clearUserSession() {
        if let frAuth = FRAuth.shared {
            FRLog.v("Clearing FRUser.currentUser")
            FRUser._staticUser = nil
            frAuth.sessionManager.setCurrentUser(user: nil)
            frAuth.sessionManager.setSSOToken(ssoToken: nil)
            try? frAuth.sessionManager.setAccessToken(token: nil)
        }
    }
    
    
    /// Saves current FRUser instance to Keychain
    func save() {
        if let frAuth = FRAuth.shared {
            FRLog.v("Saving FRUser.currentUser")
            frAuth.sessionManager.setCurrentUser(user: self)
        }
    }
    
    
    // MARK: - Debug 
    
    /// Debug description of FRUser and associated properties
    override public var debugDescription: String {
        var desc =  "\(String(describing: self))"
        desc += "\n\t\(self.token.debugDescription)"
        return desc
    }
    
    // MARK: - NSSecureCoding
    
    /// Boolean value of whether SecureCoding is supported or not
    public class var supportsSecureCoding: Bool {
        return true
    }
    
    
    /// Initializes FRUser object with NSCoder
    ///
    /// - Parameter aDecoder: NSCoder
    convenience required public init?(coder aDecoder: NSCoder) {
        guard let serverConfigData = aDecoder.decodeObject(forKey: "serverConfig") as? Data,
            let serverConfig = try? JSONDecoder().decode(ServerConfig.self, from: serverConfigData) as ServerConfig else
        {
            return nil
        }
        
        self.init(token: nil, serverConfig: serverConfig)
    }
    
    
    /// Encodes FRUser object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    public func encode(with aCoder: NSCoder) {
        if let serverConfigData: Data = try? JSONEncoder().encode(self.serverConfig) {
            aCoder.encode(serverConfigData, forKey: "serverConfig")
        }
    }
}
