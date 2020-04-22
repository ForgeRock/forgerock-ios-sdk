//
//  TokenManager.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/// TokenManager class is a management class responsible for persisting, retrieving, and refreshing OAuth2 token(s)
struct TokenManager {
    
    var oAuth2Client: OAuth2Client
    var sessionManager: SessionManager
    
    /// Initializes TokenMAnager instance with optional Access Group for shared Keychain Group identifier
    ///
    /// - Parameters:
    ///   - oAuth2Client: OAuth2Client instance for OAuth2 token protocols
    ///   - keychainManager: KeychainManager instance for secure credentials management
    public init(oAuth2Client: OAuth2Client, sessionManager: SessionManager) {
        self.oAuth2Client = oAuth2Client
        self.sessionManager = sessionManager
    }
    
    /// Persists AccessToken instance into Keychain Service
    ///
    /// - Parameter token: AccessToken instance to persist
    /// - Throws: TokenError.failToPersistToken when failed to parse AccessToken instance
    public func persist(token: AccessToken) throws {
        try self.sessionManager.setAccessToken(token: token)
    }
    
    
    /// Retrieves AccessToken object from Keychain Service
    ///
    /// - Returns: AccessToken object if it was found, and was able to decode object; otherwise nil
    /// - Throws: TokenError.failToParseToken error when retrieved data from Keychain Service failed to deserialize into AccessToken object
    func retrieveAccessTokenFromKeychain() throws -> AccessToken? {
        return try self.sessionManager.getAccessToken()
    }
    
    
    /// Retrieves AccessToken; if AccessToken expires within threshold defined in OAuth2Client, it will return a new set of OAuth2 tokens
    ///
    /// - Parameter completion: TokenCompletion block which will return an AccessToken object, or Error
    public func getAccessToken(completion: @escaping TokenCompletionCallback) {
        do {
            if let token = try self.retrieveAccessTokenFromKeychain() {
                if token.willExpireIn(threshold: self.oAuth2Client.threshold) {
                    if let refreshToken = token.refreshToken {
                        self.oAuth2Client.refresh(refreshToken: refreshToken) { (newToken, error) in
                            do {
                                newToken?.sessionToken = token.sessionToken
                                try self.sessionManager.setAccessToken(token: newToken)
                                completion(token, error)
                            }
                            catch {
                                completion(nil, error)
                            }
                        }
                    }
                    else if let ssoToken = self.sessionManager.getSSOToken() {
                        self.oAuth2Client.exchangeToken(token: ssoToken) { (token, error) in
                            do {
                                try self.sessionManager.setAccessToken(token: token)
                                completion(token, error)
                            }
                            catch {
                                completion(nil, error)
                            }
                        }
                    }
                    else {
                        completion(nil, TokenError.nullRefreshToken)
                    }
                }
                else {
                    completion(token, nil)
                }
            }
            else if let ssoToken = self.sessionManager.getSSOToken() {
                self.oAuth2Client.exchangeToken(token: ssoToken) { (token, error) in
                    do {
                        try self.sessionManager.setAccessToken(token: token)
                        completion(token, error)
                    }
                    catch {
                        completion(nil, error)
                    }
                }
            }
            else {
                completion(nil, TokenError.nullToken)
            }
        } catch {
            completion(nil, error)
        }
    }
    
    
    /// Retrieves AccessToken; if AccessToken expires within threshold defined in OAuth2Client, it will return a new set of OAuth2 tokens
    ///
    /// - NOTE: This method may perform synchronous API request if the token expires within threshold. Make sure to not call this method in Main thread
    ///
    /// - Returns: AccessToken if it was able to retrieve, or get new set of OAuth2 token
    /// - Throws: AuthError will be thrown when refresh_token request failed, or TokenError
    public func getAccessToken() throws -> AccessToken? {
        
        if let token = try self.retrieveAccessTokenFromKeychain() {
            if token.willExpireIn(threshold: self.oAuth2Client.threshold) {
                if let refreshToken = token.refreshToken {
                    let newToken = try self.oAuth2Client.refreshSync(refreshToken: refreshToken)
                    newToken.sessionToken = token.sessionToken
                    try self.sessionManager.setAccessToken(token: newToken)
                    return token
                }
                else if let ssoToken = self.sessionManager.getSSOToken() {
                    let token = try self.oAuth2Client.exchangeTokenSync(token: ssoToken)
                    try self.sessionManager.setAccessToken(token: token)
                    return token
                }
                else {
                    throw TokenError.nullRefreshToken
                }
            }
            else {
                return token
            }
        }
        else if let ssoToken = self.sessionManager.getSSOToken() {
            let token = try self.oAuth2Client.exchangeTokenSync(token: ssoToken)
            try self.sessionManager.setAccessToken(token: token)
            return token
        }
        else {
            throw TokenError.nullToken
        }
    }
    
    
    /// Refreshes OAuth2 token set using refresh_token
    /// - Parameter completion: TokenCompletion block which will return an AccessToken object, or Error
    func refresh(completion: @escaping TokenCompletionCallback) {
        do {
            if let token = try self.retrieveAccessTokenFromKeychain() {
                if let refreshToken = token.refreshToken {
                    self.oAuth2Client.refresh(refreshToken: refreshToken) { (newToken, error) in
                        do {
                            newToken?.sessionToken = token.sessionToken
                            try self.sessionManager.setAccessToken(token: newToken)
                            completion(newToken, error)
                        }
                        catch {
                            completion(nil, error)
                        }
                    }
                }
                else {
                    completion(nil, TokenError.nullRefreshToken)
                }
            }
            else {
                completion(nil, TokenError.nullToken)
            }
        }
        catch {
            completion(nil, error)
        }
    }
    
    
    /// Revokes OAuth2 token set using either of access_token or refresh_token
    /// - Parameter completion: Completion block which will return an Error if there was any error encountered
    func revoke(completion: @escaping CompletionCallback) {
        
        do {
            if let token = try self.retrieveAccessTokenFromKeychain() {
                self.oAuth2Client.revoke(accessToken: token, completion: completion)
                try? self.sessionManager.setAccessToken(token: nil)
            }
            else {
                completion(TokenError.nullToken)
            }
        }
        catch {
            completion(error)
        }
    }
}
