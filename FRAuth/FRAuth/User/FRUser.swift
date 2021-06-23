//
//  FRUser.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore


/// FRUser represents authenticated user session as FRUser object
@objc
public class FRUser: NSObject, NSSecureCoding {

    //  MARK: - Properties
    
    /**
     Singleton instance represents currently authenticated user.
     
     ## Note ##
     If SDK has not been started using *FRAuth.start()*, *FRUser.currentUser* returns nil even if user session has previously authenticated, and valid.
     *FRUser.currentUser* would only returns an object when there is either or both of following:
        - Session Token authenticated by AM's Authentication Tree
        - OAuth2 token set issued by previously authenticated Session Token
     */
    @objc
    public static var currentUser: FRUser? {
        get {
            if let staticUser = _staticUser {
                return staticUser
            }
            else if let frAuth = FRAuth.shared {
                
                FRLog.v("FRUser retrieved from SessionManager")
                if let accessToken = try? frAuth.keychainManager.getAccessToken() {
                    _staticUser = FRUser(token: accessToken)
                }
                else if let _ = frAuth.keychainManager.getSSOToken() {
                    _staticUser = FRUser(token: nil)
                }
                
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
    public var token: AccessToken? {
        get {
            if let frAuth = FRAuth.shared, let accessToken = try? frAuth.keychainManager.getAccessToken() {
                let sessionToken = frAuth.keychainManager.getSSOToken()
                if sessionToken?.value != accessToken.sessionToken {
                    FRLog.w("SDK identified current Session Token (\(sessionToken?.value ?? "null")) and Session Token (\(String(describing: accessToken.sessionToken))) associated with Access Token mismatch; to avoid misled information, SDK automatically revokes OAuth2 token set issued with previously granted Session Token.")
                    frAuth.tokenManager?.revokeAndEndSession(completion: { (error) in
                        FRLog.i("OAuth2 token set was revoked due to mismatch of Session Tokens; \(String(describing: error))")
                    })
                    return nil
                }
                
                return accessToken
            }
            
            return nil
        }
        set {
        }
    }
    
    
    //  MARK: - Init
    
    /// Initializes FRUser object with AccessToken, ServerConfig, and UserInfo (optional)
    ///
    /// - Parameters:
    ///   - token: AccessToken object associated with the user instance
    init(token: AccessToken?) {
    
        super.init()

        if let token = token {
            self.token = token
        }
        else if let frAuth = FRAuth.shared {
            self.token = try? frAuth.keychainManager.getAccessToken()
        }
    }
    
    
    //  MARK: - Login
    
    /// Logs-in user based on configuration value initialized through FRAuth.start()
    ///
    ///  *Note*:
    ///  - When there is already authenticated user's session (either with Session Token and/or OAuth2 token set), login method returns an error. If Session Token exists, but not OAuth2 token set, use _FRUser.currentUser.getAccessToken()_ to obtain OAuth2 token set using Session Token.
    ///  - FRAuth.start() must be called prior to call login
    ///
    /// - Parameter completion: Completion callback which returns FRUser instance (also accessible through FRUser.currentUser), and/or any error encountered during authentication
    @objc
    public static func login(completion:@escaping NodeCompletion<FRUser>) {
        
        if let currentUser = FRUser.currentUser {
            var hasAccessToken: Bool = false
            if let _ = currentUser.token {
                hasAccessToken = true
            }
            FRLog.v("FRUser is already logged-in; returning an error")
            completion(nil, nil, AuthError.userAlreadyAuthenticated(hasAccessToken))
        }
        else if let frAuth = FRAuth.shared {
            FRLog.v("Initiating login process")
            
            FRSession.authenticate(authIndexValue: frAuth.authServiceName) { (token: Token?, node, error) in
                completion(nil, node, error)
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
    ///  *Note*:
    ///  - When there is already authenticated user's session (either with Session Token and/or OAuth2 token set), register method returns an error. If Session Token exists, but not OAuth2 token set, use _FRUser.currentUser.getAccessToken()_ to obtain OAuth2 token set using Session Token.
    ///  - FRAuth.start() must be called prior to call register
    ///
    /// - Parameter completion: Completion callback which returns FRUser instance (also accessible through FRUser.currentUser), and/or any error encountered during registration
    @objc
    public static func register(completion:@escaping NodeCompletion<FRUser>) {
        
        if let currentUser = FRUser.currentUser {
            var hasAccessToken: Bool = false
            if let _ = currentUser.token {
                hasAccessToken = true
            }
            FRLog.v("FRUser is already logged-in; returning an error")
            completion(nil, nil, AuthError.userAlreadyAuthenticated(hasAccessToken))
        }
        else if let frAuth = FRAuth.shared {
            FRLog.v("Initiating register process")
            
            FRSession.authenticate(authIndexValue: frAuth.registerServiceName) { (token: Token?, node, error) in
                completion(nil, node, error)
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
    /// - NOTE: logout method invokes 2 APIs to invalidate user's session: 1) invokes /sessions/?_action=logout to invalidate Session Token, 2) /token/revoke to invalidate access_token and/or refresh_token (if refresh_token was granted), and 3) if id_token exists, it invokes /connect/endSession to invalidate OIDC session
    ///
    @objc
    public func logout() {
        
        var ssoTokenInvalidated = false
        let tempToken = FRUser.currentUser?.token
        if let frSession = FRSession.currentSession {
            FRLog.v("Invaliding SSO Token")
            // Revoke Session Token
            frSession.logout()
            ssoTokenInvalidated = true
        }
        
        if let frAuth = FRAuth.shared, let tokens = tempToken {
            FRLog.v("Invalidating OAuth2 token(s)")
            // Revoke OAuth2 tokens
            frAuth.tokenManager?.revoke(completion: { (error) in
                if let error = error {
                    FRLog.w("Error while invalidating OAuth2 token(s)")
                    if let nsError = error as NSError? {
                        FRLog.w("[\(nsError.domain) - \(nsError.code): \(nsError.localizedDescription)\n\t\(nsError.userInfo)]")
                    }
                }
                else {
                    FRLog.v("Invalidating OAuth2 token(s) successful")
                }
                
                if let idToken = tokens.idToken, ssoTokenInvalidated == false {
                    FRLog.v("Invalidating session using id_token")
                    // End Session if id_token exists
                    frAuth.tokenManager?.endSession(idToken: idToken, completion: { (error) in
                        
                        if let error = error {
                            FRLog.w("Error while invalidating OIDC Session")
                            if let nsError = error as NSError? {
                                FRLog.w("[\(nsError.domain) - \(nsError.code): \(nsError.localizedDescription)\n\t\(nsError.userInfo)]")
                            }
                        }
                        else {
                            FRLog.v("Invalidating OIDC Session successful")
                        }
                    })
                }
            })
        }
        
        // Clear user object
        FRUser._staticUser = nil
        // Clear Browser instance if there is anything running
        Browser.currentBrowser = nil
    }
    
    
    //  MARK: - AccessToken
    
    /// Retrieves access_token from Keychain storage, and if current access_token is expired, then consumes refresh_token to refresh access_token, and returns FRUser with newly granted access_token
    ///
    /// - Parameter completion: Completion block which returns newly refreshed FRUser object
    @objc
    public func getAccessToken(completion:@escaping UserCallback) {
        if let frAuth = FRAuth.shared, let tokenManager = frAuth.tokenManager {
            tokenManager.getAccessToken { (token, error) in
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
            FRLog.w("Invalid SDK state; missing TokenManager")
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
        if let frAuth = FRAuth.shared, let tokenManager = frAuth.tokenManager {
            if let token = try tokenManager.getAccessToken() {
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
    
    /// Revokes current OAuth2 token using access_token, or refresh_token.
    ///
    ///
    /// - Parameter completion: Completion callback that notifies the result of operation
    @objc
    public func revokeAccessToken(completion: @escaping UserCallback) {
        FRLog.v("Revoke Access Token")
        
        guard let frAuth = FRAuth.shared, let tokenManager = frAuth.tokenManager else {
            FRLog.e("Invalid SDK state; SDK must be initialized before revoking access tokens")
            completion(nil, ConfigError.invalidSDKState)
            return
        }
        
        tokenManager.revoke { (error) in
            
            self.token = nil
            self.save()
            
            // Returning updated object and optional error.
            // Results in local token been removed even if there is a network error.
            completion(self, error)
        }
    }
    
    //  MARK: - UserInfo
    
    /// Retrieves currently authenticated user's UserInfo from /userinfo endpoint
    ///
    /// - Parameter completion: Callback block which returns UserInfo object; UserInfo result is also updated to calling FRUser object instance
    @objc
    public func getUserInfo(completion: @escaping UserInfoCallback) {
        FRLog.v("Requesting UserInfo")
        
        guard let frAuth = FRAuth.shared else {
            FRLog.e("Invalid SDK state; SDK must be initialized before calling /userinfo endpoint")
            completion(nil, ConfigError.invalidSDKState)
            return
        }
        
        self.getAccessToken { (user, error) in
            
            //  AM 6.5.2 - 7.0.0
            //
            //  Endpoint: /oauth2/realms/userinfo
            //  API Version: resource=2.1,protocol=1.0
            
            var header: [String: String] = [:]
            header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
            
            if error == nil, let user = user {
                header[OAuth2.authorization] = user.buildAuthHeader()
            }
            
            let request = Request(url: frAuth.serverConfig.userInfoURL, method: .GET, headers: header, bodyParams: [:], urlParams: [:], requestType: .json, responseType: .json, timeoutInterval: frAuth.serverConfig.timeout)
            
            FRRestClient.invoke(request: request, action: Action(type: .USER_INFO)) { (result) in
                switch result {
                case .success(let response, _ ):
                    completion(UserInfo(response), nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
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
    
    
    //  MARK: - Centralized Login (External User Agent)
    
    /// Creates Browser object to perform Centralized Login (an external user-agent /authorize flow)
    ///
    /// - Returns: BrowserBuilder object that can progressively construct Browser object with configuration; BrowserBuilder may return nil if there is another Builder instance running in the application.
    @objc
    public static func browser() -> BrowserBuilder? {
        
        guard let frAuth = FRAuth.shared, let oAuth2Client = frAuth.oAuth2Client else {
            FRLog.e("Failed to generate Browser() due to invalid SDK state; SDK must be initialized and configured for OAuth2")
            return nil
        }
        
        guard (Browser.currentBrowser == nil || Browser.currentBrowser?.isInProgress ?? false) else {
            FRLog.e("There is another Browser instance running; only one instance of Browser can run at the same time.")
            return nil
        }
        
        return BrowserBuilder(oAuth2Client, frAuth.keychainManager)
    }
    
    
    // MARK: - Private methods
    
    /// Refreshes user's session with refresh_token regardless of validity of current access_token
    ///
    /// - Parameter completion: Completion callback that notifies the result of operation
    func refresh(completion:@escaping UserCallback) {
        if let frAuth = FRAuth.shared, let tokenManager = frAuth.tokenManager {
            tokenManager.refresh{ (token, error) in
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
    
    
    /// Refreshes user's session with refresh_token synchronously regardless of validity of current access_token
    /// - Throws: TokenError
    /// - Returns: FRUser object with newly renewed OAuth2 token
    func refreshSync() throws -> FRUser {
        if let frAuth = FRAuth.shared, let tokenManager = frAuth.tokenManager {
            let token = try tokenManager.refreshSync()
            self.token = token
            self.save()
            return self
        }
        else {
            FRLog.w("Invalid SDK state")
            throw ConfigError.invalidSDKState
        }
    }
    
    
    /// Saves current FRUser instance to Keychain
    func save() {
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
        self.init(token: nil)
    }
    
    
    /// Encodes FRUser object with NSCoder
    ///
    /// - Parameter aCoder: NSCoder
    public func encode(with aCoder: NSCoder) {
    }
}
