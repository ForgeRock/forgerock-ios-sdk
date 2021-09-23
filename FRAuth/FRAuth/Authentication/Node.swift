//
//  Node.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/**
 Node class is the core abstraction within an authentication tree. Trees are made up of nodes, which may modify the shared state and/or request input from the user via Callbacks. Node is also a representation of each step in the authentication flow, and keeps unique identifier and its state of the authentication flow. Node must be submitted to OpenAM to proceed or finish the authentication flow. Submitting the Node object returns one of following:
 * Result of expected type, if available
 * Another Node object instance to continue on the authentication flow
 * An error, if occurred during the authentication flow
 */
@objc(FRNode)
public class Node: NSObject {

    //  MARK: - Public properties
    
    /// A list of Callback for the state
    @objc public var callbacks: [Callback] = []
    /// authId for the authentication flow
    @objc public var authId: String
    /// Unique UUID String value of initiated AuthService flow
    @objc public var authServiceId: String
    /// Stage attribute in Page Node
    @objc public var stage: String?
    /// Header attribute in Page Node
    @objc public var pageHeader: String?
    /// Description attribute in Page Node
    @objc public var pageDescription: String?
    /// Designated AuthService name defined in OpenAM
    var serviceName: String
    /// authIndexType value in AM
    var authIndexType: String
    /// ServerConfig information for AuthService/Node API communication
    var serverConfig: ServerConfig
    /// OAuth2Client information for AuthService/Node API communication
    var oAuth2Config: OAuth2Client?
    /// TokenManager instance to manage, and persist authenticated session
    var tokenManager: TokenManager?
    /// KeychainManager instance to persist, and retrieve credentials from storage
    var keychainManager: KeychainManager?
    
    
    
    //  MARK: - Init
    
    /// Designated initialization method for Node; AuthService process will initialize Node with given response from OpenAM
    /// - Parameters:
    ///   - authServiceId: Unique UUID for current AuthService flow
    ///   - authServiceResponse: JSON response object of AuthService in OpenAM
    ///   - serverConfig: ServerConfig object for AuthService/Node communication
    ///   - serviceName: Service name for AuthService (TreeName)
    ///   - authIndexType: authIndexType value in AM (default to 'service')
    ///   - oAuth2Config: (Optional) OAuth2Client object for AuthService/Node communication for abstraction layer
    ///   - keychainManager: KeychainManager instance to persist, and retrieve credentials from secure storage
    ///   - tokenManager: TokenManager  instance to manage and persist authenticated session
    /// - Throws: `AuthError`
    init?(_ authServiceId: String, _ authServiceResponse: [String: Any], _ serverConfig: ServerConfig, _ serviceName: String, _ authIndexType: String, _ oAuth2Config: OAuth2Client? = nil, _ keychainManager: KeychainManager? = nil, _ tokenManager: TokenManager? = nil) throws {
        
        guard let authId = authServiceResponse[OpenAM.authId] as? String else {
            FRLog.e("Invalid response: missing 'authId'")
            throw AuthError.invalidAuthServiceResponse("missing or invalid 'authId'")
        }
        
        self.authServiceId = authServiceId
        self.stage = authServiceResponse[OpenAM.stage] as? String
        self.pageHeader = authServiceResponse[OpenAM.header] as? String
        self.pageDescription = authServiceResponse[OpenAM.description] as? String
        self.serverConfig = serverConfig
        self.serviceName = serviceName
        self.authIndexType = authIndexType
        self.oAuth2Config = oAuth2Config
        self.authId = authId
        
        self.keychainManager = keychainManager
        self.tokenManager = tokenManager
        
        if let callbacks = authServiceResponse[OpenAM.callbacks] as? [[String: Any]] {
            
            for callback in callbacks {
                
                // Validate if callback response contains type
                guard var callbackType = callback["type"] as? String else {
                    FRLog.e("Invalid response: Callback is missing 'type' \n\t\(callback)")
                    throw AuthError.invalidCallbackResponse(String(describing: callback))
                }
                
                //  Validate if Callback is WebAuthnCallback
                let webAuthnType = WebAuthnCallback.getWebAuthnType(callback)
                switch webAuthnType {
                //  If Callback type is WebAuthnAuthentication/Registration, manually change Callback type
                case .authentication, .registration:
                    callbackType = webAuthnType.rawValue
                    break
                default:
                    break
                }
                
                let callbackObj = try Node.transformCallback(callbackType: callbackType, json: callback)
                self.callbacks.append(callbackObj)
                
                if self.stage == nil { //Fix for SDKS-1209
                    // Support AM 6.5.2 stage property workaround with MetadataCallback
                    if let metadataCallback = callbackObj as? MetadataCallback, let outputs = metadataCallback.response[CBConstants.output] as? [[String: Any]] {
                        for output in outputs {
                            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.data, let outputValue = output[CBConstants.value] as? [String: String] {
                                self.stage = outputValue[CBConstants.stage]
                            }
                        }
                    }
                }
            }
        }
        else {
            FRLog.e("Invalid response: missing or invalid callback attribute \n\t\(authServiceResponse)")
            throw AuthError.invalidAuthServiceResponse("missing or invalid callback(S) response \(authServiceResponse)")
        }
    }

    
    //  MARK: - Static helper method
    
    /// Converts given JSON into Callback object
    /// - Parameters:
    ///   - callbackType: String value of Callback type
    ///   - json: JSON response of Callback
    /// - Throws: `AuthError`
    /// - Returns: Callback object
    static func transformCallback(callbackType: String, json: [String: Any]) throws -> Callback {

        // Validate if given callback type is supported
        guard let callbackClass = CallbackFactory.shared.supportedCallbacks[callbackType] else {
            FRLog.e("Unsupported callback: Callback is not supported in SDK \n\t\(json)")
            throw AuthError.unsupportedCallback("callback type, \(callbackType), is not supported")
        }
        
        let callback = try callbackClass.init(json: json)
        
        return callback
    }
    
    
    //  MARK: - Public methods
    
    /// Submits current Node object with Callback(s) and its given value(s) to OpenAM to proceed on authentication flow.
    ///
    /// - Parameter completion: NodeCompletion callback which returns the result of Node submission.
    public func next<T>(completion:@escaping NodeCompletion<T>) {

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
    
    /// Submits current node, and returns FRUser instance if result of node returns SSO TOken
    ///
    /// - Parameter completion: NodeCompletion<FRUser> callback that returns FRUser upon completion
    fileprivate func next(completion:@escaping NodeCompletion<FRUser>) {
        FRLog.v("Called")
        if let currentUser = FRUser.currentUser {
            FRLog.i("FRUser.currentUser retrieved from SessionManager; ignoring Node submit")
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
    
    
    /// Submits current node, and returns AccessToken instance if result of node returns SSO TOken
    ///
    /// - Parameter completion: NodeCompletion<AccessToken> callback that returns AccessToken upon completion
    fileprivate func next(completion:@escaping NodeCompletion<AccessToken>) {
        FRLog.v("Called")
        if let accessToken = try? self.keychainManager?.getAccessToken() {
            FRLog.i("access_token retrieved from SessionManager; ignoring Node submit")
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
    
    
    /// Submits current node, and returns Token instance if result of node returns SSO TOken
    ///
    /// - Parameter completion: NodeCompletion<Token> callback that returns Token upon completion
    fileprivate func next(completion:@escaping NodeCompletion<Token>) {

        let thisRequest = self.buildAuthServiceRequest()
        FRRestClient.invoke(request: thisRequest, action: Action(type: .AUTHENTICATE, payload: ["tree": self.serviceName, "type": self.authIndexType])) { (result) in
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
                    let token = Token(tokenId)
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
    
    /// Builds Dictionary object for request parameter with given list of Callback(s)
    ///
    /// - Returns: Dictionary object containing all values of Callback(s), and AuthService information
    @objc
    func buildRequestPayload() -> [String:Any] {
        
        var payload: [String: Any] = [:]
        
        payload[OpenAM.authId] = self.authId
        var callbacks: [Any] = []
        
        for callback:Callback in self.callbacks {
            callbacks.append(callback.buildResponse())
        }
        
        payload[OpenAM.callbacks] = callbacks
        
        return payload
    }
    
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
        return Request(url: self.serverConfig.authenticateURL, method: .POST, headers: header, bodyParams: self.buildRequestPayload(), urlParams: [:], requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
    }
    
    
    // - MARK: Objective-C Compatibility
    
    @objc(nextWithUserCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithUserCompletion(completion:@escaping NodeCompletion<FRUser>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithAccessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithAccessTokenCompletion(completion:@escaping NodeCompletion<AccessToken>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithTokenCompletion(completion:@escaping NodeCompletion<Token>) {
        self.next(completion: completion)
    }
}
