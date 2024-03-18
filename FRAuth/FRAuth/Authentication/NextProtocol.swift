// 
//  NextProtocol.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

public class NextProtocol: NSObject {
    
    /// A list of Callback for the state
    @objc public var callbacks: [Callback] = []
    /// authId for the authentication flow
    @objc public var authId: String?
    /// Unique UUID String value of initiated AuthService flow
    @objc public var authServiceId: String?
    /// Designated AuthService name defined in OpenAM
    var serviceName: String?
    /// authIndexType value in AM
    var authIndexType: String?
    /// ServerConfig information for AuthService/Node API communication
    var serverConfig: ServerConfig?
    /// OAuth2Client information for AuthService/Node API communication
    var oAuth2Config: OAuth2Client?
    /// TokenManager instance to manage, and persist authenticated session
    var tokenManager: TokenManager?
    /// KeychainManager instance to persist, and retrieve credentials from storage
    var keychainManager: KeychainManager?
    
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
    
    func next(completion:@escaping NodeCompletion<FRUser>) {
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
    
    func next(completion:@escaping NodeCompletion<AccessToken>) {
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
    
    func next(completion:@escaping NodeCompletion<Token>) {
        
        guard let thisRequest = try? self.buildAuthServiceRequest(),
                let authServiceId = self.authServiceId,
                let serverConfig = self.serverConfig,
                let serviceName = self.serviceName,
                let authIndexType = self.authIndexType
        else { return }
        
        let thisAction = Action(type: .AUTHENTICATE, payload: ["tree": serviceName, "type": authIndexType])
        
        self.invoke(authServiceId: authServiceId, serverConfig: serverConfig, serviceName: serviceName, authIndexType: authIndexType, request: thisRequest, action: thisAction, completion: completion)
    }
    
    func invoke(authServiceId: String, serverConfig: ServerConfig, serviceName: String, authIndexType: String, request: Request, action: Action, completion: @escaping NodeCompletion<Token>) {
        
        FRRestClient.invoke(request: request, action: action) { (result) in
            switch result {
            case .success(let response, _):
                
                // If authId received
                if let _ = response[OpenAM.authId] {
                    do {
                        let node = try Node(authServiceId, response, serverConfig, serviceName, authIndexType, self.oAuth2Config, self.keychainManager, self.tokenManager)
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
                        //If the `currentSessionToken` is nil and have OAuth2.0 tokens it means the user did a Centralized Login flow to authenticate initially. The token is now returned from either a Policy Advice and should be the same one as originaly created, or from a new authentication
                        if ((currentSessionToken == nil) && (try? keychainManager.getAccessToken()) != nil) && authIndexType == "composite_advice" {
                            // In this case we are running a transactional authorization flow, the new SSO Token is the same as the originally created one. When running Centralised login, this lived in the browser cookie storage and is unaccesssible from the app
                            // Save the SSO Token in the storage and return
                            keychainManager.setSSOToken(ssoToken: token)
                        }
                        else if let _ = try? keychainManager.getAccessToken(), token.value != currentSessionToken?.value {
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
    
    func buildAuthServiceRequest() throws -> Request {
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /json/realms/authenticate
        //  API Version: resource=2.1,protocol=1.0
        guard let serverConfig = self.serverConfig else { throw ConfigError.invalidSDKState }
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        return Request(url: serverConfig.authenticateURL, method: .POST, headers: header, bodyParams: self.buildRequestPayload(), urlParams: [:], requestType: .json, responseType: .json, timeoutInterval: serverConfig.timeout)
    }
}
