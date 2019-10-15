//
//  SessionManager.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

class SessionManager: NSObject {
    
    var keychainManager: KeychainManager
    let serverConfig: ServerConfig
    var isSSOEnabled: Bool {
        get {
            return self.keychainManager.isSharedKeychainAccessible
        }
    }
    
    
    public init(keychainManager: KeychainManager, serverConfig: ServerConfig) {
        self.keychainManager = keychainManager
        self.serverConfig = serverConfig
    }
    
    
    func getCurrentUser() -> FRUser? {
    
        if let userData = self.keychainManager.sharedStore.getData("current_user") {
            do {
                
                if #available(iOS 11.0, *) {
                    if let currentUser = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, FRUser.self, AccessToken.self, UserInfo.self], from: userData) as? FRUser {
                        currentUser.token = nil
                        let userToken = try self.getAccessToken()
                        currentUser.token = userToken
                        return currentUser
                    }
                }
                else {
                    if let currentUser = NSKeyedUnarchiver.unarchiveObject(with: userData) as? FRUser {
                        currentUser.token = nil
                        let userToken = try self.getAccessToken()
                        currentUser.token = userToken
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
    
    
    func setSSOToken(ssoToken: Token?) {
        if let token = ssoToken {
            self.keychainManager.sharedStore.set(token.value, key: "sso_token")
        }
        else {
            self.keychainManager.sharedStore.delete("sso_token")
        }
    }
    
    
    func getSSOToken() -> Token? {
        if let ssoTokenString = self.keychainManager.sharedStore.getString("sso_token") {
            return Token(ssoTokenString)
        }
        else {
            return nil
        }
    }
}
