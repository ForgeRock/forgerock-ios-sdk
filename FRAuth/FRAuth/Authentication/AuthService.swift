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
public class AuthService: NodeNext {
    
    
    //  MARK: - Init
    
    /// Designated initialization method for AuthService
    ///
    /// - Parameters:
    ///   - name: String value of AuthService name
    ///   - serverConfig: ServerConfig object for AuthService server communication
    @objc
    public init(name: String, serverConfig: ServerConfig) {
        super.init()
        
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
        super.init()
        
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
        super.init()
        
        FRLog.v("AuthService init - service: \(authIndexValue), serviceType: \(authIndexType) ServerConfig: \(serverConfig), OAuth2Client: \(String(describing: oAuth2Config)), KeychainManager: \(String(describing: keychainManager)), TokenManager: \(String(describing: tokenManager))")
        self.serviceName = authIndexValue
        self.authIndexType = authIndexType
        self.serverConfig = serverConfig
        self.oAuth2Config = oAuth2Config
        self.keychainManager = keychainManager
        self.tokenManager = tokenManager
        self.authServiceId = UUID().uuidString
    }
    
    
    override func next(completion: @escaping NodeCompletion<Token>) {
        
        // Construct Request object for AuthService flow with given serviceName
        guard let request = try? self.buildAuthServiceRequest(),
                let authServiceId = self.authServiceId,
                let serverConfig = self.serverConfig,
                let serviceName = self.serviceName,
                let authIndexType = self.authIndexType
        else { return }
        
        let action: Action
        //  For /authenticate request with suspendedId, return .RESUME_AUTHENTICATE type
        if self.authIndexType == OpenAM.suspendedId {
            action = Action(type: .RESUME_AUTHENTICATE)
        }
        //  Otherwise, regular .START_AUTHENTICATE Action type
        else {
            action = Action(type: .START_AUTHENTICATE, payload: ["tree": serviceName, "type": authIndexType])
        }
        
        self.invoke(authServiceId: authServiceId, serverConfig: serverConfig, serviceName: serviceName, authIndexType: authIndexType, request: request, action: action, completion: completion)
    }
    
    
    // - MARK: Private request build helper methods
    
    /// Builds Request object for current Node
    ///
    /// - Returns: Request object for OpenAM AuthTree submit
    override func buildAuthServiceRequest() throws -> Request {
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /json/realms/authenticate
        //  API Version: resource=2.1,protocol=1.0
        guard let serverConfig = self.serverConfig else { throw ConfigError.invalidSDKState }
        
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
        
        return Request(url: serverConfig.authenticateURL, method: .POST, headers: header, urlParams: parameter, requestType: .json, responseType: .json, timeoutInterval: serverConfig.timeout)
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
