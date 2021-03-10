//
//  OAuth2Client.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/// OAuth2 client object represents OAuth2 client, and provides methods related to OAuth2 protocol
@objc(FROAuth2Client)
public class OAuth2Client: NSObject, Codable {
    
    //  MARK: - Property
    
    /// OAuth2 client_id
    let clientId: String
    /// OAuth2 scope(s) separated by space
    let scope: String
    /// OAuth2 redirect_uri for the client
    let redirectUri: URL
    /// ServerConfig which OAuth2 client will communicate to
    let serverConfig: ServerConfig
    /// Threshold to refresh access_token in advance
    var threshold: Int
    
    
    //  MARK: - Init
    
    /// Designated initialization method for OAuth2 Client
    ///
    /// - Parameters:
    ///   - clientId: client_id of the client
    ///   - scope: set of scope(s) separated by space to request for the client; requesting scope set must be registered in the OAuth2 client
    ///   - redirectUri: redirect_uri in URL object as registered in the client
    ///   - serverConfig: ServerConfig that OAuth2 Client will communicate to
    ///   - threshold: threshold in seconds to refresh access_token before it actually expires
    @objc
    public init (clientId: String, scope: String, redirectUri: URL, serverConfig: ServerConfig, threshold: Int = 60) {
        
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.scope = scope
        self.serverConfig = serverConfig
        self.threshold = threshold
    }
    
    
    // - MARK: Token Revocation
    
    /// Revokes access_token and any associated token(s)
    ///
    /// - Parameters:
    ///   - accessToken: AccessToken object to revoke
    ///   - completion: Completion callback to notify the result of operation
    @objc
    public func revoke(accessToken: AccessToken, completion: @escaping CompletionCallback) {
        // Construct parameter for the request
        var parameter:[String: String] = [:]
        let token = accessToken.refreshToken ?? accessToken.value
        parameter[OAuth2.token] = token
        parameter[OAuth2.clientId] = self.clientId
        
        let request = Request(url: self.serverConfig.tokenRevokeURL, method: .POST, headers: [:], bodyParams: parameter, urlParams: [:], requestType: .urlEncoded, responseType: .json, timeoutInterval: self.serverConfig.timeout)
        
        FRRestClient.invoke(request: request, action: Action(type: .REVOKE_TOKEN)) { (result) in
            switch result {
            case .success(_ , _):
                completion(nil)
                break
            case .failure(let error):
                completion(error)
                break
            }
        }
    }
    
    
    /// Invalidates OIDC sessions
    /// - Parameters:
    ///   - idToken: OIDC id_token
    ///   - completion: Completion callback
    @objc public func endSession(idToken: String, completion: @escaping CompletionCallback) {
        var parameter:[String: String] = [:]
        parameter[OAuth2.clientId] = self.clientId
        parameter[OAuth2.idTokenHint] = idToken
        
        let request = Request(url: self.serverConfig.endSessionURL, method: .GET, headers: [:], bodyParams: [:], urlParams: parameter, requestType: .urlEncoded, responseType: .json, timeoutInterval: self.serverConfig.timeout)
        
        FRRestClient.invoke(request: request, action: Action(type: .END_SESSION)) { (result) in
            switch result {
            case .success(_ , _):
                completion(nil)
                break
            case .failure(let error):
                completion(error)
                break
            }
        }
    }
    
    
    // - MARK: Toekn Refresh
    
    /// Refreshes OAuth2 token set asynchronously with given refresh_token
    ///
    /// - Parameters:
    ///   - refreshToken: refresh_token to be consumed for requesting new OAuth2 token set
    ///   - completion: Completion callback to notify the result of operation with AccessToken object or an error
    @objc public func refresh(refreshToken: String, completion: @escaping TokenCompletionCallback) {
        
        let request = self.buildRefreshRequest(refreshToken: refreshToken)
        
        FRRestClient.invoke(request: request, action: Action(type: .REFRESH_TOKEN)) { (result) in
            switch result {
            case .success(let response, _ ):
                if let accessToken = AccessToken(tokenResponse: response) {
                    do {
                        try FRAuth.shared?.keychainManager.setAccessToken(token: accessToken)
                    }
                    catch {
                        FRLog.e("Unexpected error while storing AccessToken: \(error.localizedDescription)")
                    }
                    completion(accessToken, nil)
                }
                else {
                    completion(nil, AuthError.invalidTokenResponse(response))
                }
            case .failure(let error):
                if let apiError = error as? AuthApiError, let oAuth2Error = apiError.convertToOAuth2Error() {
                    FRLog.i("refresh_tokn grant returned OAuth2 related error; converting the error to OAuth2Error")
                    completion(nil, oAuth2Error)
                }
                else {
                    completion(nil, error)
                }
                break
            }
        }
    }
    
    
    /// Refreshes OAuth2 token set synchronously with given refresh_token
    ///
    /// ## Important Note ##
    /// This method is synchronous operation; please be aware consequences, and perform this method in **Main** thread if necessary.
    ///
    /// - Parameter refreshToken: refresh_token to be consumed for requesting new OAuth2 token set
    /// - Returns: AccessToken object if refreshing token was successful
    /// - Throws: AuthError or TokenError
    @objc public func refreshSync(refreshToken: String) throws -> AccessToken {
        
        let request = self.buildRefreshRequest(refreshToken: refreshToken)
        let result = FRRestClient.invokeSync(request: request, action: Action(type: .REFRESH_TOKEN))
        
        switch result {
        case .success(let response, _ ):
            if let accessToken = AccessToken(tokenResponse: response) {
                do {
                    try FRAuth.shared?.keychainManager.setAccessToken(token: accessToken)
                }
                catch {
                    FRLog.e("Unexpected error while storing AccessToken: \(error.localizedDescription)")
                }
                return accessToken
            }
            else {
                throw AuthError.invalidTokenResponse(response)
            }
        case .failure(let error):
            if let apiError = error as? AuthApiError, let oAuth2Error = apiError.convertToOAuth2Error() {
                FRLog.i("refresh_tokn grant returned OAuth2 related error; converting the error to OAuth2Error")
                throw oAuth2Error
            }
            else {
                throw error
            }
        }
    }
    
    
    // - MARK: Token Request
    
    
    /// Exchanges SSOToken received from OpenAM asynchronously to OAuth2 token set using OAuth2 Authorization Code flow.
    ///
    /// - Parameters:
    ///   - token: Token object (SSO Token) received from OpenAM through AuthService/Node authentication flow
    ///   - completion: Completion callback which returns set of token(s), or error upon completion of request
    @objc
    public func exchangeToken(token: Token, completion: @escaping TokenCompletionCallback) {
       
        let ssoToken = token.value
        let pkce = PKCE()
        let request = self.buildAuthorizeRequest(ssoToken: ssoToken, pkce: pkce)
        
        FRRestClient.invoke(request: request, action: Action(type: .AUTHORIZE)) { (result) in
            switch result {
            case .success(_ , let httpResponse):
                    
                //  Capture the request redirection, and identify redirect_uri
                if let httpResponse:HTTPURLResponse = httpResponse as? HTTPURLResponse, let redirectURLAsString:String = httpResponse.allHeaderFields["Location"] as? String {
                    
                    let redirectURL = URL(string: redirectURLAsString)
                    
                    //  If authorization_code was included in the redirecting request, extract the code, and continue with token endpoint
                    if let authCode = redirectURL?.valueOf("code") {
                        
                        let request = self.buildTokenWithCodeRequest(code: authCode, pkce: pkce)
                        FRRestClient.invoke(request: request, action: Action(type: .EXCHANGE_TOKEN), completion: { (result) in
                            switch result {
                            case .success(let response, _):
                                if let accessToken = AccessToken(tokenResponse: response, sessionToken: ssoToken) {
                                    completion(accessToken, nil)
                                }
                                else {
                                    completion(nil, AuthError.invalidTokenResponse(response))
                                }
                            case .failure(let error):
                                completion(nil, error)
                                break
                            }
                        })
                    }
                    else if let _ = redirectURL?.valueOf("error"), let _ = redirectURL?.valueOf("error_description") {
                        completion(nil, OAuth2Error.convertOAuth2Error(urlValue: redirectURL?.absoluteString))
                    }
                    else {
                        completion(nil, OAuth2Error.missingOrInvalidRedirectURI(redirectURL?.absoluteString))
                    }
                }
                else {
                    completion(nil, OAuth2Error.missingOrInvalidRedirectURI(nil))
                }
                break
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    
    /// Exchanges authorization code for OAuth2 token set
    /// - Parameters:
    ///   - code: authorization_code
    ///   - pkce: PKCE information requested in /authorize
    ///   - completion: Completion callback
    func exchangeToken(code: String, pkce: PKCE? = nil, completion: @escaping TokenCompletionCallback) {

        let request = self.buildTokenWithCodeRequest(code: code, pkce: pkce)
        FRRestClient.invoke(request: request, action: Action(type: .EXCHANGE_TOKEN), completion: { (result) in
            switch result {
            case .success(let response, _):
                if let accessToken = AccessToken(tokenResponse: response) {
                    completion(accessToken, nil)
                }
                else {
                    completion(nil, AuthError.invalidTokenResponse(response))
                }
            case .failure(let error):
                completion(nil, error)
                break
            }
        })
    }
    
    
    /// Exchanges SSOToken received from OpenAM synchronously to OAuth2 token set using OAuth2 Authorization Code flow.
    ///
    /// ## Important Note ##
    /// This method is synchronous operation; please be aware consequences, and perform this method in **Main** thread if necessary.
    ///
    /// - Parameter token: Token object (SSO Token) received from OpenAM through AuthService/Node authentication flow
    /// - Returns: AccessToken object if exchanging token was successful
    /// - Throws: AuthError or TokenError
    public func exchangeTokenSync(token: Token) throws -> AccessToken? {
        let ssoToken = token.value
        let pkce = PKCE()
        let request = self.buildAuthorizeRequest(ssoToken: ssoToken, pkce: pkce)
        
        let result = FRRestClient.invokeSync(request: request, action: Action(type: .AUTHORIZE))
        switch result {
        case .success(_ , let httpResponse):
            
            //  Capture the request redirection, and identify redirect_uri
            if let httpResponse:HTTPURLResponse = httpResponse as? HTTPURLResponse, let redirectURLAsString:String = httpResponse.allHeaderFields["Location"] as? String {
                
                let redirectURL = URL(string: redirectURLAsString)
                
                //  If authorization_code was included in the redirecting request, extract the code, and continue with token endpoint
                if let authCode = redirectURL?.valueOf("code") {
                    
                    let request = self.buildTokenWithCodeRequest(code: authCode, pkce: pkce)
                    let result = FRRestClient.invokeSync(request: request, action: Action(type: .EXCHANGE_TOKEN))
                    switch result {
                    case .success(let response, _ ):
                        if let accessToken = AccessToken(tokenResponse: response, sessionToken: ssoToken) {
                            return accessToken
                        }
                        else {
                            throw AuthError.invalidTokenResponse(response)
                        }
                    case .failure(let error):
                        throw error
                    }
                }
                else if let _ = redirectURL?.valueOf("error"), let _ = redirectURL?.valueOf("error_description") {
                    throw OAuth2Error.convertOAuth2Error(urlValue: redirectURL?.absoluteString)
                }
                else {
                    throw OAuth2Error.missingOrInvalidRedirectURI(redirectURL?.absoluteString)
                }
            }
            else {
                throw OAuth2Error.missingOrInvalidRedirectURI(nil)
            }
        case .failure(let error):
            throw error
        }
    }
    
    
    // - MARK: Private request build helper methods
    
    /// Builds a request for refreshing token with refresh_token
    ///
    /// - Parameter refreshToken: String value of refresh_token
    /// - Returns: Request object
    func buildRefreshRequest(refreshToken: String) -> Request {
        
        //  Construct parameter for the request
        var parameter:[String:String] = [:]
        parameter[OAuth2.responseType] = OAuth2.token
        parameter[OAuth2.clientId] = self.clientId
        parameter[OAuth2.scope] = self.scope
        parameter[OAuth2.grantType] = OAuth2.refreshToken
        parameter[OAuth2.refreshToken] = refreshToken
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /oauth2/realms/access_token
        //  API Version: resource=2.1,protocol=1.0
        
        let header: [String: String] = [OpenAM.acceptAPIVersion: OpenAM.apiResource21 + "," + OpenAM.apiProtocol10]
        
        return Request(url: self.serverConfig.tokenURL, method: .POST, headers: header, bodyParams: parameter, urlParams: [:], requestType: .urlEncoded, responseType: .json, timeoutInterval: self.serverConfig.timeout)
    }
    
    
    /// Builds Authorize request with SSOToken
    ///
    /// - Parameters:
    ///   - ssoToken: String value of SSOToken
    ///   - pkce: PKCE instance for authorization code flow
    /// - Returns: Request object
    func buildAuthorizeRequest(ssoToken: String, pkce: PKCE) -> Request {
        
        //  Construct parameter for the request
        var parameter: [String: String] = [:]
        parameter[OAuth2.responseType] = OAuth2.code
        parameter[self.serverConfig.cookieName] = ssoToken
        parameter[OAuth2.clientId] = self.clientId
        parameter[OAuth2.scope] = self.scope
        parameter[OAuth2.redirecUri] = self.redirectUri.absoluteString
        parameter[OAuth2.state] = pkce.state
        parameter[OAuth2.codeChallenge] = pkce.codeChallenge
        parameter[OAuth2.codeChallengeMethod] = pkce.codeChallengeMethod
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /oauth2/realms/authorize
        //  API Version: resource=2.1,protocol=1.0
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        
        return Request(url: self.serverConfig.authorizeURL, method: .GET, headers: header, urlParams:parameter, requestType: .urlEncoded, responseType: .urlEncoded, timeoutInterval: self.serverConfig.timeout)
    }
    
    
    /// Builds /authorize request for an external user-agent based on given OAuth2 client information
    /// - Parameters:
    ///   - pkce: PKCE information to be sent for /authorize
    ///   - customParams: Any custom parameters in Dictionary
    /// - Returns: Request object
    func buildAuthorizeRequestForExternalAgent(pkce: PKCE, customParams: [String: String]? = nil) -> Request {
        //  Construct parameter for the request
        var parameter: [String: String] = [:]
        parameter[OAuth2.responseType] = OAuth2.code
        parameter[OAuth2.clientId] = self.clientId
        parameter[OAuth2.scope] = self.scope
        parameter[OAuth2.redirecUri] = self.redirectUri.absoluteString
        parameter[OAuth2.state] = pkce.state
        parameter[OAuth2.codeChallenge] = pkce.codeChallenge
        parameter[OAuth2.codeChallengeMethod] = pkce.codeChallengeMethod
        
        if let customParams = customParams {
            for (key, value) in customParams {
                parameter[key] = value
            }
        }
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /oauth2/realms/authorize
        //  API Version: resource=2.1,protocol=1.0
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        
        return Request(url: self.serverConfig.authorizeURL, method: .GET, headers: header, urlParams:parameter, requestType: .urlEncoded, responseType: .urlEncoded, timeoutInterval: self.serverConfig.timeout)
    }
    
    
    /// Builds Token request with Authorization Code
    ///
    /// - Parameters:
    ///   - code: String value of authorization_code
    ///   - pkce: PKCE instace for authorization code flow
    /// - Returns: Request object
    func buildTokenWithCodeRequest(code: String, pkce: PKCE?) -> Request {
        
        //  Construct the request parameter
        var parameter:[String:String] = [:]
        parameter[OAuth2.code] = code
        parameter[OAuth2.redirecUri] = self.redirectUri.absoluteString
        parameter[OAuth2.clientId] = self.clientId
        parameter[OAuth2.grantType] = OAuth2.grantTypeAuthCode
        if let pkce = pkce {
            parameter[OAuth2.codeVerifier] = pkce.codeVerifider
        }
        
        //  AM 6.5.2 - 7.0.0
        //
        //  Endpoint: /oauth2/realms/access_token
        //  API Version: resource=2.1,protocol=1.0
        
        var header: [String: String] = [:]
        header[OpenAM.acceptAPIVersion] = OpenAM.apiResource21 + "," + OpenAM.apiProtocol10
        
        //  Call /token service to exchange auth code to OAuth token set
        return Request(url: self.serverConfig.tokenURL, method: .POST, headers: header, bodyParams: parameter, requestType: .urlEncoded, responseType: .json, timeoutInterval: self.serverConfig.timeout)
    }
}
