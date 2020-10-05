//
//  SessionManager.swift
//  FRAuth
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/// SessionManager is a representation of management class for FRAuth's managing session
class SessionManager: NSObject {
    
    /// KeychainManager responsible for Keychain Service activities
    var keychainManager: KeychainManager
    /// ServerConfig instance of SessionManager
    let serverConfig: ServerConfig
    /// Boolean representation of whether SSO is enabled or not; evaluated with Shared Keychain Access Group
    var isSSOEnabled: Bool {
        get {
            return self.keychainManager.isSharedKeychainAccessible
        }
    }
    
    /// Singletone object of SessionManager
    @objc static var currentManager: SessionManager? {
        get {
            if let frAuth = FRAuth.shared {
                return frAuth.sessionManager
            }
            
            return nil
        }
    }
    
    
    //  MARK: - Init
    
    /// Initializes SessionManager object with KeychainManager, and ServerConfig instances
    /// - Parameter keychainManager: KeychainManager class responsible for Keychain Service
    /// - Parameter serverConfig: ServerConfig that contains AM server information
    init(keychainManager: KeychainManager, serverConfig: ServerConfig) {
        self.keychainManager = keychainManager
        self.serverConfig = serverConfig
    }
    
    
    //  MARK: - FRUser
    
    /// Returns currently authenticated user object through OAuth2 service
    func getCurrentUser() -> FRUser? {
    
        if let userData = self.keychainManager.sharedStore.getData("current_user") {
            do {
                
                if #available(iOS 11.0, *) {
                    if let currentUser = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, FRUser.self, AccessToken.self, UserInfo.self], from: userData) as? FRUser {
                        return currentUser
                    }
                }
                else {
                    if let currentUser = NSKeyedUnarchiver.unarchiveObject(with: userData) as? FRUser {
                        return currentUser
                    }
                }
            }
            catch {
                FRLog.e("Error while retrieving FRUser.currentUser from SessionManager: \(error.localizedDescription)")
            }
        }
        else if let token = try? self.getAccessToken() {
            return FRUser(token: token, serverConfig: self.serverConfig)
        }
        
        return nil
    }
    
    
    /// Sets current user authenticated through OAuth2 service, and stores into Keychain Service
    /// - Parameter user: FRUser object instance authenticated with OAuth2 service
    func setCurrentUser(user: FRUser?) {
        
        if let thisUser = user {
            do {
                if #available(iOS 11.0, *) {
                    let userData = try NSKeyedArchiver.archivedData(withRootObject: thisUser, requiringSecureCoding: false)
                    self.keychainManager.sharedStore.set(userData, key: "current_user")
                }
                else {
                    let userData = NSKeyedArchiver.archivedData(withRootObject: thisUser)
                    self.keychainManager.sharedStore.set(userData, key: "current_user")
                }
            }
            catch {
                FRLog.e("Error while storing FRUser.currentUser into SessionManager: \(error.localizedDescription)")
            }
        }
        else {
            self.keychainManager.sharedStore.delete("current_user")
        }
    }
    
    
    //  MARK: - AccessToken
    
    /// Returns current session's AccessToken object with OAuth2 token set
    func getAccessToken() throws -> AccessToken? {
        if let tokenData = self.keychainManager.privateStore.getData("access_token") {
            do {
                
                if #available(iOS 11.0, *) {
                    let token = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [AccessToken.self, Token.self], from: tokenData) as? AccessToken
                    return token
                }
                else {
                    if let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData) as? AccessToken {
                        return token
                    }
                }
            }
            catch {
                throw TokenError.failToParseToken(error.localizedDescription)
            }
        }
        return nil
    }
    
    
    /// Sets AccessToken object with OAuth2 token set, and stores into Keychain Service
    /// - Parameter token: AccessToken object that contains OAuth2 token set
    func setAccessToken(token: AccessToken?) throws {
        if let thisToken = token {
            do {
                
                if #available(iOS 11.0, *) {
                    let tokenData = try NSKeyedArchiver.archivedData(withRootObject: thisToken, requiringSecureCoding: true)
                    self.keychainManager.privateStore.set(tokenData, key: "access_token")
                }
                else {
                    let tokenData = NSKeyedArchiver.archivedData(withRootObject: thisToken)
                    self.keychainManager.privateStore.set(tokenData, key: "access_token")
                }
            }
            catch {
                throw TokenError.failToParseToken(error.localizedDescription)
            }
        }
        else {
            self.keychainManager.privateStore.delete("access_token")
        }
    }
    
    
    //  MARK: - SSO Token
    
    /// Returns current session's Token object that represents SSO Token
    func getSSOToken() -> Token? {
        if let ssoTokenString = self.keychainManager.sharedStore.getString("sso_token") {
            return Token(ssoTokenString)
        }
        else {
            return nil
        }
    }
    
    
    /// Sets SSO Token and stores into Keychain Service
    /// - Parameter ssoToken: Token object that represents SSO Token
    func setSSOToken(ssoToken: Token?) {
        if let token = ssoToken {
            self.keychainManager.sharedStore.set(token.value, key: "sso_token")
        }
        else {
            self.keychainManager.sharedStore.delete("sso_token")
        }
    }
    
        
    /// Revokes currently authenticated and stored SSO Token and removes it from Keychain Service
    func revokeSSOToken() -> Void {

        if let ssoToken = self.getSSOToken() {
            FRLog.v("Invalidating SSO Token")
            var parameter: [String: String] = [:]
            parameter[OpenAM.tokenId] = ssoToken.value
            var header: [String: String] = [:]
            header[self.serverConfig.cookieName] = ssoToken.value
            
            //  AM 6.5.2 - 7.0.0
            //
            //  Endpoint: /json/realms/sessions
            //  API Version: resource=3.1
            
            header[OpenAM.acceptAPIVersion] = OpenAM.apiResource31
            var urlParam: [String: String] = [:]
            urlParam[OpenAM.action] = OpenAM.logout

            // Deletes SSO token from Keychain Service
            self.setSSOToken(ssoToken: nil)
            
            // Deletes all Cookie from Cookie Store
            FRLog.i("Deleting all cookies from Cookie Store as invalidating Session Token.")
            self.keychainManager.cookieStore.deleteAll()
            
            let request = Request(url: self.serverConfig.sessionURL, method: .POST, headers: header, bodyParams: parameter, urlParams: urlParam, requestType: .json, responseType: .json, timeoutInterval: self.serverConfig.timeout)
            FRRestClient.invoke(request: request, action: Action(type: .LOGOUT)) { (result) in
                switch result {
                case .success( _, _ ):
                    FRLog.v("SSO Token was successfully revoked")
                    break
                case .failure(let error):
                    FRLog.w("SSO Token revoke request failed: \(error.localizedDescription)")
                    break
                }
            }
        }
        else {
            FRLog.w("Trying to revoke SSO Token, no SSO Token found")
        }
    }
}
