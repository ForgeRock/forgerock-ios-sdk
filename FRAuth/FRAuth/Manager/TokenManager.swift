//
//  TokenManager.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Dispatch

/// TokenManager class is a management class responsible for persisting, retrieving, and refreshing OAuth2 token(s)
struct TokenManager {
    
    var oAuth2Client: OAuth2Client
    var keychainManager: KeychainManager
    
    /// Semaphore lock to make TokenManager thread-safe
    private let lock = DispatchSemaphore(value: 1)
    
    /// Initializes TokenManager instance with optional Access Group for shared Keychain Group identifier
    ///
    /// - Parameters:
    ///   - oAuth2Client: OAuth2Client instance for OAuth2 token protocols
    ///   - keychainManager: KeychainManager instance for secure credentials management
    public init(oAuth2Client: OAuth2Client, keychainManager: KeychainManager) {
        self.oAuth2Client = oAuth2Client
        self.keychainManager = keychainManager
    }
    
    
    /// Retrieves AccessToken; if AccessToken expires within threshold defined in OAuth2Client, it will return a new set of OAuth2 tokens
    ///
    /// - Parameter completion: TokenCompletion block which will return an AccessToken object, or Error
    public func getAccessToken(completion: @escaping TokenCompletionCallback) {
        
        // 1. Call the `retrieveToken` method.
        // This safely handles initial token retrieval and any session mismatch errors.
        self.retrieveToken { (token, error) in
            
            // Handle any errors from the initial retrieval (e.g., keychain failure).
            if let error = error {
                FRLog.e("An error occurred during initial token retrieval: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            // 2. If a token was successfully retrieved, proceed to check its expiration.
            if let validToken = token {
                if validToken.willExpireIn(threshold: self.oAuth2Client.threshold) {
                    // Token is about to expire, so attempt to refresh it.
                    self._handleRefreshToken(token: validToken, completion: completion)
                } else {
                    // Token is valid and not expiring. Return it directly.
                    FRLog.v("Access token is still valid; returning existing token.")
                    completion(validToken, nil)
                }
            } else {
                // 3. If `retrieveToken` returned nil, no token was found.
                // Proceed to get a new token using the SSO token.
                FRLog.w("No OAuth2 token found; exchanging SSO Token for OAuth2 tokens.")
                self.refreshUsingSSOToken(completion: completion)
            }
        }
    }
    
    
    /// Retrieves AccessToken; if AccessToken expires within threshold defined in OAuth2Client, it will return a new set of OAuth2 tokens
    ///
    /// - NOTE: This method may perform synchronous API request if the token expires within threshold. Make sure to not call this method in Main thread
    ///
    /// - Returns: AccessToken if it was able to retrieve, or get new set of OAuth2 token
    /// - Throws: AuthError will be thrown when refresh_token request failed, or TokenError
    public func getAccessToken() throws -> AccessToken? {
        
        // Use the instance's lock to ensure atomicity and prevent race conditions
        // from multiple threads calling this synchronous method.
        self.lock.wait()
        defer {
            self.lock.signal()
        }
        
        // Create a semaphore to block the current thread.
        let semaphore = DispatchSemaphore(value: 0)
        
        // Variables to capture the result from the async function.
        var resultToken: AccessToken?
        var resultError: Error?
        
        // Call the asynchronous version of the function.
        self.getAccessToken { (token, error) in
            // Capture the results from the completion handler.
            resultToken = token
            resultError = error
            
            // Signal the semaphore to unblock the waiting thread.
            semaphore.signal()
        }
        
        // Wait here until the async function calls the completion handler and signals the semaphore.
        semaphore.wait()
        
        // After being unblocked, check for an error and throw it if it exists.
        if let error = resultError {
            throw error
        }
        
        // Otherwise, return the token.
        return resultToken
    }
    
    
    /// Refreshes the current OAuth2 token set.
    /// It will handle session mismatches, then attempt to use the refresh_token,
    /// falling back to the SSO token if necessary.
    /// - Parameter completion: The callback delivering the result.
    func refresh(completion: @escaping TokenCompletionCallback) {
        // First, retrieve a session-valid token.
        // retrieveToken handles the session mismatch check internally.
        self.retrieveToken { (token, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let token = token {
                // A valid token was found, so proceed to refresh it.
                self._handleRefreshToken(token: token, completion: completion)
            }
            else {
                // retrieveToken returned nil, meaning no token was stored.
                FRLog.e("No OAuth2 token(s) found to refresh.")
                completion(nil, TokenError.nullToken)
            }
        }
    }
    
    
    /// Synchronously refreshes the current OAuth2 token set.
    /// It will handle session mismatches, then attempt to use the refresh_token,
    /// falling back to the SSO token if necessary.
    /// - Throws: TokenError or other underlying errors.
    /// - Returns: The renewed AccessToken.
    func refreshSync() throws -> AccessToken? {
        
        // Use the instance's lock to ensure this operation is atomic.
        self.lock.wait()
        defer {
            self.lock.signal()
        }
        
        // Create a semaphore to block the current thread until the async work is done.
        let semaphore = DispatchSemaphore(value: 0)
        
        // Declare variables to capture the result from the completion handler.
        var resultToken: AccessToken?
        var resultError: Error?
        
        // Call the primary asynchronous refresh function.
        self.refresh { (token, error) in
            // Store the results.
            resultToken = token
            resultError = error
            
            // Signal the semaphore to unblock the thread.
            semaphore.signal()
        }
        
        // Wait here until the signal is received.
        semaphore.wait()
        
        // Check for an error and throw it if one occurred.
        if let error = resultError {
            throw error
        }
        
        // Return the resulting token.
        return resultToken
    }
    
    
    /// Revokes OAuth2 token set using either of access_token or refresh_token
    /// - Parameter completion: Completion block which will return an Error if there was any error encountered
    func revoke(completion: @escaping CompletionCallback) {
        do {
            if let token = try self.keychainManager.getAccessToken() {
                try self.keychainManager.setAccessToken(token: nil)
                self.oAuth2Client.revoke(accessToken: token) { (error) in
                    completion(error)
                }
            }
            else {
                completion(TokenError.nullToken)
            }
        }
        catch {
            FRLog.e("Unexpected error while revoking AccessToken: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    
    /// Ends OIDC Session with given id_token
    /// - Parameters:
    ///   - idToken: id_token to be revoked, and OIDC session
    ///   - completion: Completion callback to notify the result
    func endSession(idToken: String, completion: @escaping CompletionCallback) {
        self.oAuth2Client.endSession(idToken: idToken, completion: completion)
    }
    
    
    /// Ends OIDC Session with given id_token and revokes OAuth2 token(s)
    /// - Parameter completion: Completion callback to notify the result
    func revokeAndEndSession(completion: @escaping CompletionCallback) {
        do {
            if let token = try self.keychainManager.getAccessToken() {
                let dispatchGroup = DispatchGroup()
                var capturedError: Error?
                
                // End session if id_token exists
                if let idToken = token.idToken {
                    dispatchGroup.enter() // Enter group for endSession
                    self.endSession(idToken: idToken) { (error) in
                        if let error = error {
                            FRLog.v("Session ended with error: \(error.localizedDescription)")
                            capturedError = error // Capture the first error
                        } else {
                            FRLog.v("Session ended successfully.")
                        }
                        dispatchGroup.leave() // Leave group for endSession
                    }
                }
                
                // Revoke OAuth2 token(s)
                dispatchGroup.enter() // Enter group for revoke
                self.revoke { (error) in
                    if let error = error, capturedError == nil {
                        capturedError = error // Capture the first error
                    }
                    dispatchGroup.leave() // Leave group for revoke
                }
                
                // Notify when both operations are complete
                dispatchGroup.notify(queue: .main) {
                    completion(capturedError)
                }
            }
            else {
                completion(TokenError.nullToken)
            }
        }
        catch {
            completion(error)
        }
    }
    
    
    /// Renews OAuth 2 token(s) with SSO Token
    /// - Throws: AuthApiError, TokenError
    /// - Returns: AccessToken object containing OAuth 2 token if it was successful
    func refreshUsingSSOTokenSync() throws -> AccessToken? {
        if let ssoToken = self.keychainManager.getSSOToken() {
            do {
                let token = try self.oAuth2Client.exchangeTokenSync(token: ssoToken)
                try self.keychainManager.setAccessToken(token: token)
                return token
            }
            catch {
                if error is OAuth2Error || error is AuthApiError {
                    FRLog.i("OAuth2Error or AuthApiError received while /authorize flow with SSO Token; no more valid credentials and user authentication is required.")
                    FRLog.w("Removing all credentials and state")
                    self.clearCredentials()
                    throw AuthError.userAuthenticationRequired
                }
                else {
                    FRLog.e("Unexpected error captured during /authorize flow with SSO Token - \(error.localizedDescription)")
                    throw error
                }
            }
        }
        else {
            throw TokenError.nullToken
        }
    }
    
    
    /// Renews OAuth 2 token(s) with SSO token
    /// - Parameter completion: Completion callback to notify the result
    func refreshUsingSSOToken(completion: @escaping TokenCompletionCallback) {
        if let ssoToken = self.keychainManager.getSSOToken() {
            self.oAuth2Client.exchangeToken(token: ssoToken) { (token, error) in
                do {
                    if error is OAuth2Error || error is AuthApiError {
                        FRLog.i("OAuth2Error or AuthApiError received while /authorize flow with SSO Token; no more valid credentials and user authentication is required.")
                        FRLog.w("Removing all credentials and state")
                        self.clearCredentials()
                        completion(nil, AuthError.userAuthenticationRequired)
                    }
                    else {
                        if error == nil {
                            try self.keychainManager.setAccessToken(token: token)
                        }
                        completion(token, error)
                    }
                }
                catch {
                    FRLog.e("Unexpected error captured during /authorize flow with SSO Token - \(error.localizedDescription)")
                    completion(nil, error)
                }
            }
        }
        else {
            completion(nil, TokenError.nullToken)
        }
    }
    
    
    /// Renews OAuth 2 token(s) with refresh_token
    /// - Parameter token: AccessToken object to be consumed for renewal
    /// - Throws: AuthApiError, TokenError
    /// - Returns: AccessToken object containing OAuth 2 token if it was successful
    func refreshUsingRefreshTokenSync(token: AccessToken) throws -> AccessToken? {
        if let refreshToken = token.refreshToken {
            let newToken = try self.oAuth2Client.refreshSync(refreshToken: refreshToken)
            newToken.sessionToken = token.sessionToken
            //  Update AccessToken's refresh_token if new AccessToken doesn't have refresh_token, and old one does.
            if newToken.refreshToken == nil, token.refreshToken != nil {
                FRLog.i("Newly granted OAuth2 token from refresh_token grant is missing refresh_token; reuse previously granted refresh_token")
                newToken.refreshToken = token.refreshToken
            }
            try self.keychainManager.setAccessToken(token: newToken)
            return newToken
        }
        else {
            throw TokenError.nullRefreshToken
        }
    }
    
    
    /// Renews OAuth 2 token(s) with refresh_token
    /// - Parameters:
    ///   - token: AccessToken object to be consumed for renewal
    ///   - completion: Completion callback to notify the result
    func refreshUsingRefreshToken(token: AccessToken, completion: @escaping TokenCompletionCallback) {
        if let refreshToken = token.refreshToken {
            self.oAuth2Client.refresh(refreshToken: refreshToken) { (newToken, error) in
                do {
                    if error == nil, let newToken = newToken {
                        newToken.sessionToken = token.sessionToken
                        //  Update AccessToken's refresh_token if new AccessToken doesn't have refresh_token, and old one does.
                        if newToken.refreshToken == nil, token.refreshToken != nil {
                            FRLog.i("Newly granted OAuth2 token from refresh_token grant is missing refresh_token; reuse previously granted refresh_token")
                            newToken.refreshToken = token.refreshToken
                        }
                        try self.keychainManager.setAccessToken(token: newToken)
                    }
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
    
    
    /// Clears all credentials locally as there is no more valid credentials to renew user's session
    func clearCredentials() {
        self.keychainManager.cookieStore.deleteAll()
        let _ = try? self.keychainManager.setAccessToken(token: nil)
        self.keychainManager.setSSOToken(ssoToken: nil)
        FRSession._staticSession = nil
        FRUser._staticUser = nil
        Browser.currentBrowser = nil
    }
    
    
    /// Revoke given Access Token without using the Refresh Token
    func revokeToken(_ token: AccessToken, completion: @escaping CompletionCallback) {
        self.oAuth2Client.revoke(accessToken: token, useRefreshToken: false) { (error) in
            completion(error)
        }
    }
    
    /// Retrieves AccessToken without checking expiry; if Session Token associated with AccessToken mismatches with current SSO Token, it will revoke the token set and return nil
    /// - Parameter completion: Completion callback to notify the result
    /// - Throws: TokenError
    /// - Returns: AccessToken if it was able to retrieve, or nil if there was no token found
    func retrieveToken(completion: @escaping TokenCompletionCallback) {
        do {
            guard let token = try self.keychainManager.getAccessToken() else {
                // No token found, complete with nil
                completion(nil, nil)
                return
            }
            
            if let ssoToken = self.keychainManager.getSSOToken()?.value, ssoToken != token.sessionToken {
                // Mismatch found: revoke, then refresh.
                FRLog.w("SDK identified Session Token mismatch; revoking token set.")
                
                self.revoke { (error) in
                    if let error = error {
                        // If revoke fails, pass the error up
                        completion(nil, error)
                        return
                    }
                    
                    FRLog.i("Token set revoked; proceeding to refresh using SSO token.")
                    // After revoke succeeds, call the async refresh
                    self.refreshUsingSSOToken(completion: completion)
                }
            }
            else {
                // No mismatch, token is valid. Complete successfully with the current token.
                completion(token, nil)
            }
        } catch {
            // Catch any errors from keychainManager and complete with the error.
            completion(nil, error)
        }
    }
    
    /// Retrieves AccessToken; if AccessToken expires within threshold defined in OAuth2Client, it will return a new set of OAuth2 tokens
    /// - NOTE: This method may perform synchronous API request if the token expires within threshold. Make sure to not call this method in Main thread
    /// - Returns: AccessToken if it was able to retrieve, or get new set of OAuth2 token
    func retrieveTokenSync() throws -> AccessToken? {
        
        // Maintain the original lock to ensure the entire operation is thread-safe.
        self.lock.wait()
        defer {
            self.lock.signal()
        }
        
        // Create a semaphore to block the current thread.
        let semaphore = DispatchSemaphore(value: 0)
        
        // Variables to capture the result from the async function.
        var resultToken: AccessToken?
        var resultError: Error?
        
        // Call the asynchronous version of the function.
        self.retrieveToken { (token, error) in
            // Capture the results from the completion handler.
            resultToken = token
            resultError = error
            
            // Signal the semaphore to unblock the waiting thread.
            semaphore.signal()
        }
        
        // Wait here until the async function signals completion.
        semaphore.wait()
        
        // After unblocking, check if an error occurred and throw it.
        if let error = resultError {
            throw error
        }
        
        // Otherwise, return the retrieved token.
        return resultToken
    }
    
    
    // MARK: - Private Refactoring Helpers
    
    /// Private helper to manage the refresh-token grant and its specific fallback logic.
    private func _handleRefreshToken(token: AccessToken, completion: @escaping TokenCompletionCallback) {
        self.refreshUsingRefreshToken(token: token) { (refreshedToken, refreshError) in
            if let tokenError = refreshError as? TokenError, case .nullRefreshToken = tokenError {
                FRLog.w("No refresh_token found; exchanging SSO Token for OAuth2 tokens")
                self.refreshUsingSSOToken(completion: completion)
            } else if let oAuthError = refreshError as? OAuth2Error, case .invalidGrant = oAuthError {
                FRLog.w("refresh_token grant failed; exchanging SSO Token for OAuth2 tokens")
                self.refreshUsingSSOToken(completion: completion)
            } else {
                completion(refreshedToken, refreshError)
            }
        }
    }
    
    /// Private sync helper to manage the refresh-token grant and its specific fallback logic.
    private func _handleRefreshTokenSync(token: AccessToken) throws -> AccessToken? {
        do {
            return try self.refreshUsingRefreshTokenSync(token: token)
        }
        catch TokenError.nullRefreshToken {
            FRLog.w("No refresh_token found; exchanging SSO Token for OAuth2 tokens")
            return try self.refreshUsingSSOTokenSync()
        }
        catch OAuth2Error.invalidGrant {
            FRLog.w("refresh_token grant failed; exchanging SSO Token for OAuth2 tokens")
            return try self.refreshUsingSSOTokenSync()
        }
    }
}
