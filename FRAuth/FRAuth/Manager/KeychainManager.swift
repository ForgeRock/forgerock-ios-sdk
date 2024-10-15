//
//  KeychainManager.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/// KeychainManager is responsible to manage all Keychain Services maintained and controlled by SDK
struct KeychainManager {
    
    //  MARK: - Constants
    
    /// Keychain Service types for all storages in SDK
    enum KeychainStoreType: String {
        case local = ".local"
        case shared = ".shared"
        case cookie = ".cookie"
        case deviceIdentifier = "com.forgerock.ios.deviceIdentifierService"
    }
    
    /// Storage key for credentials
    enum StorageKey: String {
        case accessToken = "access_token"
        case ssoToken = "sso_token"
        case primaryService = "primaryService"
        case primaryServiceEncrypted = "primaryService-encrypted"
        case successUrl = "successUrl"
        case realm = "realm"
    }
    
    /// String constant for SecuredKey's application tag
    let securedKeyTag: String = "com.forgerock.ios.securedKey.identifier"
    /// String constant for default service
    let defaultService: String = "com.forgerock.ios.keychainservice"
    /// String constant for default bundle identifier
    let defaultBundleIdentifier: String = "com.forgerock.ios.sdk"
    
    
    //  MARK: - Properties
    
    /// String value of currently designated server host to create a unique storage identifier
    var currentService: String
    /// String value of Access Group for the application(s)
    var accessGroup: String?
    /// Private Keychain Service storage (local)
    var privateStore: KeychainService
    /// Shared Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var sharedStore: KeychainService
    /// Cookie Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var cookieStore: KeychainService
    /// Device Identifier Keychain Service storage (shared); shared across all applications with same Access Group and within same Apple Developer Program
    var deviceIdentifierStore: KeychainService
    /// Primary Service Keychain Service storage (local); to keep track of currently designated server host to identify the storage
    var primaryServiceStore: KeychainService
    /// Boolean indicator whether or not shared Keychain Service is accessible
    var isSharedKeychainAccessible: Bool = false
    /// SecuredKey object that is used for encrypting/decrypting data in Keychain Service
    var securedKey: SecuredKey?
    
    
    //  MARK: - Init
    
    /// Initializes KeychainManager instance
    /// - Parameter baseUrl: Base URL of designated server host to uniquely identify storage identifier
    /// - Parameter accessGroup: AccessGroup as defined in Application Project's Capabilities tab
    public init?(baseUrl: String, accessGroup: String? = nil) throws {
        
        // Define currentService based on primary server
        let service = self.defaultService
        let currentService = baseUrl + "/" + service
        self.primaryServiceStore = KeychainService(service: service)
        guard var appBundleIdentifier = Bundle.main.bundleIdentifier else {
            throw ConfigError.invalidConfiguration("Bundle Identifier is missing")
        }
        appBundleIdentifier = "-" + appBundleIdentifier
        
        if let accessGroup = accessGroup {
            // If Access Group was provided, construct KeychainService with Access Group
            
            // Validate whether given Access Group is accessible or not
            if !KeychainService.validateAccessGroup(service: currentService, accessGroup: accessGroup) {
                throw ConfigError.invalidAccessGroup(accessGroup)
            }
            
            var validatedAccessGroup = accessGroup
            if let appleTeamId = KeychainService.getAppleTeamId(), !accessGroup.hasPrefix(appleTeamId) {
                // If Apple TeamId prefix is found, and accessGroup provided doesn't contain, append it
                validatedAccessGroup = appleTeamId + "." + accessGroup
            }
            self.accessGroup = validatedAccessGroup
        }
        
        
        // Create SecuredKey if available
        if let securedKey = SecuredKey(applicationTag: self.securedKeyTag, accessGroup: self.accessGroup, accessibility: self.primaryServiceStore.options.accessibility) {
            self.securedKey = securedKey
        }
        
        if self.primaryServiceStore.getString(StorageKey.primaryService.rawValue) == nil {
            // If there is no previous primaryService, create one
            FRLog.i("Creating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: StorageKey.primaryService.rawValue)
            
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        } else if let previousService = self.primaryServiceStore.getString(StorageKey.primaryService.rawValue), currentService != previousService {
            // If primaryService currently stored is different from what's passed through parameter
            FRLog.i("Detected different primary server URL; clearing credentials for previous server")
            KeychainManager.clearAllKeychainStore(service: previousService, accessGroup: accessGroup)
            
            FRLog.i("Updating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: StorageKey.primaryService.rawValue)
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        }
        
        self.currentService = currentService
        
        if let accessGroup = accessGroup {
            self.privateStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
            self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
            self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
            
            // Constructs Device Identifier storage with specific Keychain Options
            var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
            option.accessibility = .alwaysThisDeviceOnly
            self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
            
            self.isSharedKeychainAccessible = true
        }
        else {
            // If Access Group is not provided, construct KeychainService without Access Group
            self.privateStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
            self.sharedStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.shared.rawValue, securedKey: self.securedKey)
            self.cookieStore = KeychainService(service: currentService + appBundleIdentifier + KeychainStoreType.cookie.rawValue, securedKey: self.securedKey)
            
            // Constructs Device Identifier storage with specific Keychain Options
            var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue)
            option.accessibility = .alwaysThisDeviceOnly
            self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
        }
    }
    
    
    //  MARK: - SSO Token
    
    /// Returns current session's Token object that represents SSO Token
    func getSSOToken() -> Token? {
        if let ssoTokenString = self.sharedStore.getString(StorageKey.ssoToken.rawValue) {
            let successUrl = self.sharedStore.getString(StorageKey.successUrl.rawValue) ?? ""
            let realm = self.sharedStore.getString(StorageKey.realm.rawValue) ?? ""
            return Token(ssoTokenString, successUrl: successUrl, realm: realm)
        }
        else {
            return nil
        }
    }
    
    
    /// Stores SSOToken into designated Keychain Service, or removes SSOToken when nil
    /// - Parameter ssoToken: Token object
    /// - Returns: Boolean result of operation
    @discardableResult func setSSOToken(ssoToken: Token?) -> Bool {
        if let token = ssoToken {
            return self.sharedStore.set(token.value, key: StorageKey.ssoToken.rawValue)
            && self.sharedStore.set(token.successUrl, key: StorageKey.successUrl.rawValue)
            && self.sharedStore.set(token.realm, key: StorageKey.realm.rawValue)
        }
        else {
            return self.sharedStore.delete(StorageKey.ssoToken.rawValue)
            && self.sharedStore.delete(StorageKey.successUrl.rawValue)
            && self.sharedStore.delete(StorageKey.realm.rawValue)
        }
    }
    
    
    //  MARK: - AccessToken
    
    /// Stores AccessToken into designated Keychain Service, or removes AccessToken when nil
    /// - Parameter token: AccessToken object
    /// - Throws: `TokenError`
    /// - Returns: Boolean result of operation
    @discardableResult func setAccessToken(token: AccessToken?) throws -> Bool {
        if let thisToken = token {
            do {
                if #available(iOS 11.0, *) {
                    let tokenData = try NSKeyedArchiver.archivedData(withRootObject: thisToken, requiringSecureCoding: true)
                    return self.privateStore.set(tokenData, key: StorageKey.accessToken.rawValue)
                }
                else {
                    let tokenData = NSKeyedArchiver.archivedData(withRootObject: thisToken)
                    return self.privateStore.set(tokenData, key: StorageKey.accessToken.rawValue)
                }
            }
            catch {
                throw TokenError.failToParseToken(error.localizedDescription)
            }
        }
        else {
            return self.privateStore.delete(StorageKey.accessToken.rawValue)
        }
    }
    
    
    /// Retrieves AccessToken object from the Keychain Service
    /// - Throws: `TokenError`
    /// - Returns: AccessToken object if exists
    func getAccessToken() throws -> AccessToken? {
        if let tokenData = self.privateStore.getData(StorageKey.accessToken.rawValue) {
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
    
    //  MARK: - Instance helper methods
    
    /// Validates with current SecuredKey whether or not data can be decrypted as SecuredKey may change by numerous factors
    func validateEncryption() {
        // If SecuredKey is not found, but encrypted data is found, clear all Keychain Service
        if self.securedKey == nil, self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) != nil {
            FRLog.w("Secured key was not found with encrypted data; clearing credentials from KeychainServices")
            self.primaryServiceStore.delete(StorageKey.primaryServiceEncrypted.rawValue)
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
        }
        // If SecuredKey is found, but no encrypted data is found, clear all Keychain Service
        else if let securedKey = self.securedKey, self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) == nil {
            FRLog.w("Secured key was found without encrypted data; clearing credentials from KeychainServices")
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
            let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
            self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
        }
        // If SecuredKey is found, and encrypted data is found, validate the data with decryption
        else if let securedKey = self.securedKey, let encryptedData = self.primaryServiceStore.getData(StorageKey.primaryServiceEncrypted.rawValue) {
            
            if let decryptedData = securedKey.decrypt(data: encryptedData) {
                let decryptedString = String(decoding: decryptedData, as: UTF8.self)
                if decryptedString != currentService {
                    FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                    KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                    let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                    self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
                }
            }
            else {
                FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                self.primaryServiceStore.set(encryptedData!, key: StorageKey.primaryServiceEncrypted.rawValue)
            }
        }
    }
    
    
    //  MARK: - static helper methods
    
    /// Clears All (PrivateStore, SharedStore, and CookieStore) Keychain Services with given service identifier and AccessGroup; PrimaryService, and DeviceIdentifier Stores will never be cleared and will always be persisted within the device.
    /// - Parameter service: Service identifier
    /// - Parameter accessGroup: AcessGroup identifier
    static func clearAllKeychainStore(service: String, accessGroup: String?) {
        guard var appBundleIdentifier = Bundle.main.bundleIdentifier else {
            FRLog.e("Bundle Identifier is missing")
            return
        }
        appBundleIdentifier = "-" + appBundleIdentifier
        // Initiate old stores, and delete all items
        let oldPrivateStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.local.rawValue)
        oldPrivateStore.deleteAll()
        if let accessGroup = accessGroup, KeychainService.validateAccessGroup(service: service, accessGroup: accessGroup) {
          let oldSharedStore = KeychainService(service: service + KeychainStoreType.shared.rawValue, accessGroup: accessGroup)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup)
          oldCookieStore.deleteAll()
        }
        else {
          let oldSharedStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.shared.rawValue)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + appBundleIdentifier + KeychainStoreType.cookie.rawValue)
          oldCookieStore.deleteAll()
        }
    }
}
