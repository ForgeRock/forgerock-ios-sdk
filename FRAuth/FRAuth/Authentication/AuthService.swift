//
//  AuthService.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/**
 AuthService represents Authentication Tree in OpenAM to initiate authentication flow with OpenAM. Initiating AuthService returns one of following:
    * Result of expected type, if available
    * A Node object instance to continue on the authentication flow
    * An error, if occurred during the authentication flow
 
 ## Notes ##
     * Any Callback type returned from AM must be supported within CallbackFactory.shared.supportedCallbacks.
     * Any custom Callback must be implemented by inheriting Callback class, and be registered through CallbackFactory.shared.registerCallback(callbackType:callbackClass:).
 */
@objc(FRAuthService)
public class AuthService: NSObject {
    
    //  MARK: - Property
    
    /// String value of AuthService name registered in AM
    @objc public internal(set) var serviceName: String
    /// Unique UUID String value of initiated AuthService flow
    @objc public internal(set) var authServiceId: String
    
    /// authIndexType value in AM
    var authIndexType: String
    /// ServerConfig that contains OpenAM server information
    var serverConfig: ServerConfig
    /// OAuth2CLient that contains OpenAM's OAuth2 client information
    var oAuth2Config: OAuth2Client?
    /// TokenManager instance to manage, and persist authenticated session
    var tokenManager: TokenManager?
    /// KeychainManager instance to persist, and retrieve credentials from storage
    var keychainManager: KeychainManager?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for AuthService
    ///
    /// - Parameters:
    ///   - name: String value of AuthService name
    ///   - serverConfig: ServerConfig object for AuthService server communication
    @objc
    public init(name: String, serverConfig: ServerConfig) {
        FRLog.v("AuthService init - service: \(name), ServerConfig: \(serverConfig)")
        self.serviceName = name
        self.authIndexType = OpenAM.service
        self.serverConfig = serverConfig
        self.authServiceId = UUID().uuidString
    }
    
    
    /// Initializes AuthService instance with suspendedId
    /// - Parameters:
    ///   - suspendedId: suspendedId to resume Authentication Tree flow
    ///   - serverConfig: ServerConfig object for AuthService server communication
    ///   - oAuth2Config: OAuth2Client object for AuthService OAuth2 protocol upon completion of authentication flow, and when SSOToken received, AuthService automatically exchanges the token to OAuth2 token set
    ///   - keychainManager: KeychainManager instance to persist, and retrieve credentials from secure storage
    ///   - tokenManager: TokenManager  instance to manage and persist authenticated session
    init(suspendedId: String, serverConfig: ServerConfig, oAuth2Config: OAuth2Client?, keychainManager: KeychainManager? = nil, tokenManager: TokenManager? = nil) {
        FRLog.v("AuthService init - suspendedId: \(suspendedId), ServerConfig: \(serverConfig), OAuth2Client: \(String(describing: oAuth2Config)), KeychainManager: \(String(describing: keychainManager)), TokenManager: \(String(describing: tokenManager))")
        self.serviceName = suspendedId
        self.authIndexType = OpenAM.suspendedId
        self.serverConfig = serverConfig
        self.oAuth2Config = oAuth2Config
        self.keychainManager = keychainManager
        self.tokenManager = tokenManager
        self.authServiceId = UUID().uuidString
    }
    
    
    /// Initializes AuthService instance with service name, ServerConfig, and optional OAuth2Client
    /// OAuth2Client is used, and when provided, AuthService exchanges SSO Token to OAuth2 token set upon completion
    ///
    /// - Parameters:
    ///   - authIndexValue: String value of Authentication Tree name
    ///   - serverConfig: ServerConfig object for AuthService server communication
    ///   - oAuth2Config: OAuth2Client object for AuthService OAuth2 protocol upon completion of authentication flow, and when SSOToken received, AuthService automatically exchanges the token to OAuth2 token set
    ///   - keychainManager: KeychainManager instance to persist, and retrieve credentials from secure storage
    ///   - tokenManager: TokenManager  instance to manage and persist authenticated session   
    ///   - authIndexType: String value of Authentication Tree type   
    init(authIndexValue: String, serverConfig: ServerConfig, oAuth2Config: OAuth2Client?, keychainManager: KeychainManager? = nil, tokenManager: TokenManager? = nil, authIndexType: String = OpenAM.service) {
        FRLog.v("AuthService init - service: \(authIndexValue), serviceType: \(authIndexType) ServerConfig: \(serverConfig), OAuth2Client: \(String(describing: oAuth2Config)), KeychainManager: \(String(describing: keychainManager)), TokenManager: \(String(describing: tokenManager))")
        self.serviceName = authIndexValue
        self.authIndexType = authIndexType
        self.serverConfig = serverConfig
        self.oAuth2Config = oAuth2Config
        self.keychainManager = keychainManager
        self.tokenManager = tokenManager
        self.authServiceId = UUID().uuidString
    }
    
    
    // MARK: Public
    
    /// Submits current Node object with Callback(s) and its given value(s) to OpenAM to proceed on authentication flow.
    ///
    /// - Parameter completion: NodeCompletion callback which returns the result of Node submission.
    public func next<T>(completion: @escaping NodeCompletion<T>) {
        
        if T.self as AnyObject? === Token.self {
            next { (token: Token?, node, error) in
                completion(token as? T, node, error)
            }
        }
        else if T.self as AnyObject? === AccessToken.self {
            next { (token: AccessToken?, node, error) in
                completion(token as? T, node, error)
            }
        }
        else if T.self as AnyObject? === FRUser.self {
            next { (user: FRUser?, node, error) in
                completion(user as? T, node, error)
            }
        }
        else {
            completion(nil, nil, AuthError.invalidGenericType)
        }
    }
    
    
    // MARK: Private/internal methods to handle different expected type of result
    
    fileprivate func next(completion: @escaping NodeCompletion<FRUser>) {
        if let currentUser = FRUser.currentUser, currentUser.token != nil {
            FRLog.i("FRUser.currentUser retrieved from SessionManager; ignoring AuthService submit")
            completion(currentUser, nil, nil)
        }
        else {
            self.next { (accessToken: AccessToken?, node, error) in
                if let token = accessToken {
                    let user = FRUser(token: token)
                    
                    completion(user, nil, nil)
                }
                else {
                    completion(nil, node, error)
                }
            }
        }
    }
    
    
    fileprivate func next(completion: @escaping NodeCompletion<AccessToken>) {
    
        if let accessToken = try? self.keychainManager?.getAccessToken() {
            FRLog.i("access_token retrieved from SessionManager; ignoring AuthService submit")
            completion(accessToken, nil, nil)
        }
        else {
            self.next { (token: Token?, node, error) in
                
                if let tokenId = token {
                    // If OAuth2Client is provided (for abstraction layer)
                    if let oAuth2Client = self.oAuth2Config {
                        // Exchange 'tokenId' (SSOToken) to OAuth2 token set
                        oAuth2Client.exchangeToken(token: tokenId, completion: { (accessToken, error) in
                            // Return an error if failed
                            if let error = error {
                                completion(nil, nil, error)
                            }
                            else {
                                
                                if let token = accessToken {
                                    do {
                                        try self.keychainManager?.setAccessToken(token: token)
                                    }
                                    catch {
                                        FRLog.e("Unexpected error while storing AccessToken: \(error.localizedDescription)")
                                    }
                                }
                                
                                // Return AccessToken
                                completion(accessToken, nil, nil)
                            }
                        })
                    }
                    else {
                        completion(nil, nil, AuthError.invalidOAuth2Client)
                    }
                }
                else {
                    completion(nil, node, error)
                }
            }
        }
    }
    
    
    fileprivate func next(completion: @escaping NodeCompletion<Token>) {
        
        // Construct Request object for AuthService flow with given serviceName
        let request = self.buildAuthServiceRequest()
        
        var action: Action?
        //  For /authenticate request with suspendedId, return .RESUME_AUTHENTICATE type
        if self.authIndexType == OpenAM.suspendedId {
            action = Action(type: .RESUME_AUTHENTICATE)
        }
        //  Otherwise, regular .START_AUTHENTICATE Action type
        else {
            action = Action(type: .START_AUTHENTICATE, payload: ["tree": self.serviceName, "type": self.authIndexType])
        }
        
        // Invoke request
        FRRestClient.invoke(request: request, action: action) { (result) in
            switch result {
            case .success(let response, _):
                
                // If authId received
                if let _ = response[OpenAM.authId] {
                    do {
                        let node = try Node(self.authServiceId, response, self.serverConfig, self.serviceName, self.authIndexType, self.oAuth2Config, self.keychainManager, self.tokenManager)
                        completion(nil, node, nil)
                    } catch let authError as AuthError {
                        completion(nil, nil, authError)
                    } catch {
                        completion(nil, nil, error)
                    }
                }
                else if let tokenId = response[OpenAM.tokenId] as? String {
                    let successUrl = response[OpenAM.successUrl] as? String ?? ""
                    let realm = response[OpenAM.realm] as? String ?? ""
                    let token = Token(tokenId, successUrl: successUrl, realm: realm)
                    if let keychainManager = self.keychainManager {
                        let currentSessionToken = keychainManager.getSSOToken()
                        if let _ = try? keychainManager.getAccessToken(), token.value != currentSessionToken?.value {
                            FRLog.w("SDK identified existing Session Token (\(currentSessionToken?.value ?? "nil")) and received Session Token (\(token.value))'s mismatch; to avoid misled information, SDK automatically revokes OAuth2 token set issued with existing Session Token.")
                            if let tokenManager = self.tokenManager {
                                tokenManager.revokeAndEndSession { (error) in
                                    FRLog.i("OAuth2 token set was revoked due to mismatch of Session Tokens; \(error?.localizedDescription ?? "")")
                                }
                            }
                            else {
                                FRLog.i("TokenManager is not found; OAuth2 token set was removed from the storage")
                                do {
                                    try keychainManager.setAccessToken(token: nil)
                                }
                                catch {
                                    FRLog.e("Unexpected error while removing AccessToken: \(error.localizedDescription)")
                                }
                            }
                        }
                        keychainManager.setSSOToken(ssoToken: token)
                    }
                    
                    completion(token, nil, nil)
                }
                else {
                    completion(nil, nil, nil)
                }
                break
            case .failure(let error):
                completion(nil, nil, error)
                break
            }
        }
    }
    
    
    // - MARK: Private request build helper methods
    
    /// Builds Request object for current Node
    ///
    /// - Returns: Request object for OpenAM AuthTree submit
    func buildAuthServiceRequest() -> Request {
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /json/realms/authenticate
        //  API Version: resource=2.1,protocol=1.0
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        var parameter: [String: String] = [:]
        
        //  If authIndexType is suspendedId, only add suspendedId for AuthService
        if self.authIndexType == OpenAM.suspendedId {
            parameter[OpenAM.suspendedId] = self.serviceName
        }
        else {
            //  Set authIndexType, and authIndexValue
            parameter[OpenAM.authIndexType] = self.authIndexType
            parameter[OpenAM.authIndexValue] = self.serviceName
        }
        
        return Request(url: self.serverConfig.authenticateURL, method: .POST, headers: header, urlParams: parameter, requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
    }
    
    
    // - MARK: Objective-C Compatibility
    
    @objc(nextWithUserCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithUserCompletion(completion: @escaping NodeCompletion<FRUser>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithAccessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithAccessTokenCompletion(completion: @escaping NodeCompletion<AccessToken>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithTokenCompletion(completion: @escaping NodeCompletion<Token>) {
        self.next(completion: completion)
    }
}
