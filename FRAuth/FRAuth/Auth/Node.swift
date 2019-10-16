//
//  Node.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

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
    /// Designated AuthService name defined in OpenAM
    @objc public var serviceName: String
    /// Stage attribute of Node
    @objc public var stage: String?
    /// ServerConfig information for AuthService/Node API communication
    private var serverConfig: ServerConfig
    /// OAuth2Client information for AuthService/Node API communication
    private var oAuth2Config: OAuth2Client?
    /// Optional SessionManager for SDK's abstraction layer
    private var sessionManager: SessionManager?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for Node; AuthService process will initialize Node with given response from OpenAM
    ///
    /// - Parameters:
    ///   - authServiceId: Unique UUID for current AuthService flow
    ///   - authServiceResponse: JSON response object of AuthService in OpenAM
    ///   - serverConfig: ServerConfig object for AuthService/Node communication
    ///   - serviceName: Service name for AuthService (TreeName)
    ///   - oAuth2Config: (Optional) OAuth2Client object for AuthService/Node communication for abstraction layer
    /// - Throws: AuthError error may be thrown from parsing AuthService response, and parsing Callback(s)
    init?(_ authServiceId: String, _ authServiceResponse: [String: Any], _ serverConfig: ServerConfig, _ serviceName: String, _ oAuth2Config: OAuth2Client? = nil, _ sessionManager: SessionManager? = nil) throws {
        
        guard let authId = authServiceResponse[OpenAM.authId] as? String else {
            FRLog.e("Invalid response: missing 'authId'")
            throw AuthError.invalidAuthServiceResponse("missing or invalid 'authId'")
        }
        
        self.authServiceId = authServiceId
        self.stage = authServiceResponse[OpenAM.stage] as? String
        self.serverConfig = serverConfig
        self.serviceName = serviceName
        self.oAuth2Config = oAuth2Config
        self.authId = authId
        
        self.sessionManager = sessionManager
        
        if let callbacks = authServiceResponse[OpenAM.callbacks] as? [[String: Any]] {
            
            for callback in callbacks {
                
                // Validate if callback response contains type
                guard let callbackType = callback["type"] as? String else {
                    FRLog.e("Invalid response: Callback is missing 'type' \n\t\(callback)")
                    throw AuthError.invalidCallbackResponse(String(describing: callback))
                }
                // Validate if given callback type is supported
                guard let callbackClass = CallbackFactory.shared.supportedCallbacks[callbackType] else {
                    FRLog.e("Unsupported callback: Callback is not supported in SDK \n\t\(callback)")
                    throw AuthError.unsupportedCallback("callback type, \(callbackType), is not supported")
                }
                
                do {
                    // Construct callback object based on class type, and throw an error if it fails
                    self.callbacks.append(try callbackClass.init(json: callback))
                } catch let authError as AuthError {
                    FRLog.e("Invalid response: invalid Callback response; failed to construct \(callbackType)\n\tReason: \(authError.localizedDescription)")
                    throw authError
                }
            }
        }
        else {
            FRLog.e("Invalid response: missing or invalid callback attribute \n\t\(authServiceResponse)")
            throw AuthError.invalidAuthServiceResponse("missing or invalid callback(S) response \(authServiceResponse)")
        }
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
                    let user = FRUser(token: token, serverConfig: self.serverConfig)
                    self.sessionManager?.setCurrentUser(user: user)
                    
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
        if let accessToken = try? self.sessionManager?.getAccessToken() {
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
                                    try? self.sessionManager?.setAccessToken(token: token)
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
        FRLog.v("Called")
        if let sessionManager = self.sessionManager, let ssoToken = sessionManager.getSSOToken() {
            FRLog.i("SSO Token retrieved from SessionManager; ignoring Node submit")
            completion(ssoToken, nil, nil)
        }
        else {
            let thisRequest = self.buildAuthServiceRequest()
            RestClient.shared.invoke(request: thisRequest) { (result) in
                switch result {
                case .success(let response, _):
                    
                    // If token received
                    if let tokenId = response[OpenAM.tokenId] as? String {
                        let token = Token(tokenId)
                        if let sessionManager = self.sessionManager {
                            sessionManager.setSSOToken(ssoToken: token)
                        }
                        
                        completion(token, nil, nil)
                    }
                    else {
                        // If token was not received
                        do {
                            let node = try Node(self.authServiceId, response, self.serverConfig, self.serviceName, self.oAuth2Config, self.sessionManager)
                            completion(nil, node, nil)
                        } catch let authError as AuthError {
                            completion(nil, nil, authError)
                        } catch {
                            completion(nil, nil, error)
                        }
                    }
                    break
                case .failure(let error):
                    completion(nil, nil, error)
                    break
                }
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
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        var parameter: [String: String] = [:]
        parameter[OpenAM.authIndexType] = OpenAM.service
        parameter[OpenAM.authIndexValue] = self.serviceName
        return Request(url: self.serverConfig.treeURL, method: .POST, headers: header, bodyParams: self.buildRequestPayload(), urlParams: parameter, requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
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
