//
//  KeychainManager.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// KeychainManager is responsible to manage all Keychain Services maintained and controlled by SDK
struct KeychainManager {
    
    /// Keychain Service types for all storages in SDK
    enum KeychainStoreType: String {
        case local = ".local"
        case shared = ".shared"
        case cookie = ".cookie"
        case deviceIdentifier = "com.forgerock.ios.deviceIdentifierService"
    }
    
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
    
    /// Initializes KeychainManager instance
    /// - Parameter baseUrl: Base URL of designated server host to uniquely identify storage identifier
    /// - Parameter accessGroup: AccessGroup as defined in Application Project's Capabilities tab
    public init?(baseUrl: String, accessGroup: String? = nil) throws {
        
        // Define currentService based on primary server
        let service = "com.forgerock.ios.keychainservice"
        let currentService = baseUrl + "/" + service
        self.primaryServiceStore = KeychainService(service: service)
        
        // Create SecuredKey if available
        if let securedKey = SecuredKey(applicationTag: "com.forgerock.ios.securedKey.identifier") {
            self.securedKey = securedKey
        }
        
        if self.primaryServiceStore.getString("primaryService") == nil {
            // If there is no previous primaryService, create one
            FRLog.i("Creating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: "primaryService")
            
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: "primaryService-encrypted")
            }
        } else if let previousService = self.primaryServiceStore.getString("primaryService"), currentService != previousService {
            // If primaryService currently stored is different from what's passed through parameter
            FRLog.i("Detected different primary server URL; clearing credentials for previous server")
            KeychainManager.clearAllKeychainStore(service: previousService, accessGroup: accessGroup)
            
            FRLog.i("Updating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: "primaryService")
            // If SecuredKey exsits, stored encrypted 'currentService' string
            if let securedKey = self.securedKey, let stringData = currentService.data(using: .utf8), let encryptedData = securedKey.encrypt(data: stringData) {
                self.primaryServiceStore.set(encryptedData, key: "primaryService-encrypted")
            }
        }
        
        self.currentService = currentService
        
        if let accessGroup = accessGroup {
            // If Access Group was provided, construct KeychainService with Access Group
            self.accessGroup = accessGroup
            
            // Validate whether given Access Group is accessible or not
            if KeychainService.validateAccessGroup(service: currentService, accessGroup: accessGroup) {
                self.privateStore = KeychainService(service: currentService + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
                self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
                self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup, securedKey: self.securedKey)
                
                // Constructs Device Identifier storage with specific Keychain Options
                var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
                option.accessibility = .alwaysThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
                
                self.isSharedKeychainAccessible = true
            }
            else {
                throw ConfigError.invalidAccessGroup(accessGroup)
            }
        }
        else {
            // If Access Group is not provided, construct KeychainService without Access Group
            self.privateStore = KeychainService(service: currentService + KeychainStoreType.local.rawValue, securedKey: self.securedKey)
            self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue, securedKey: self.securedKey)
            self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue, securedKey: self.securedKey)
            
            // Constructs Device Identifier storage with specific Keychain Options
            var option = KeychainOptions(service: KeychainStoreType.deviceIdentifier.rawValue)
            option.accessibility = .alwaysThisDeviceOnly
            self.deviceIdentifierStore = KeychainService(options: option, securedKey: self.securedKey)
        }
    }
    
    
    /// Validates with current SecuredKey whether or not data can be decrypted as SecuredKey may change by numerous factors
    func validateEncryption() {
        // If SecuredKey is not found, but encrypted data is found, clear all Keychain Service
        if self.securedKey == nil, self.primaryServiceStore.getData("primaryService-encrypted") != nil {
            FRLog.w("Secured key was not found with encrypted data; clearing credentials from KeychainServices")
            self.primaryServiceStore.delete("primaryService-encrypted")
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
        }
        // If SecuredKey is found, but no encrypted data is found, clear all Keychain Service
        else if let securedKey = self.securedKey, self.primaryServiceStore.getData("primaryService-encrypted") == nil {
            FRLog.w("Secured key was found without encrypted data; clearing credentials from KeychainServices")
            KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
            let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
            self.primaryServiceStore.set(encryptedData!, key: "primaryService-encrypted")
        }
        // If SecuredKey is found, and encrypted data is found, validate the data with decryption
        else if let securedKey = self.securedKey, let encryptedData = self.primaryServiceStore.getData("primaryService-encrypted") {
            
            if let decryptedData = securedKey.decrypt(data: encryptedData) {
                let decryptedString = String(decoding: decryptedData, as: UTF8.self)
                if decryptedString != currentService {
                    FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                    KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                    let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                    self.primaryServiceStore.set(encryptedData!, key: "primaryService-encrypted")
                }
            }
            else {
                FRLog.w("Failed to decrypt data using current SecuredKey; clearing credentials from KeychainServices")
                KeychainManager.clearAllKeychainStore(service: currentService, accessGroup: accessGroup)
                let encryptedData = securedKey.encrypt(data: currentService.data(using: .utf8)!)
                self.primaryServiceStore.set(encryptedData!, key: "primaryService-encrypted")
            }
        }
    }
    
    
    /// Clears All (PrivateStore, SharedStore, and CookieStore) Keychain Services with given service identifier and AccessGroup; PrimaryService, and DeviceIdentifier Stores will never be cleared and will always be persisted within the device.
    /// - Parameter service: Service identifier
    /// - Parameter accessGroup: AcessGroup identifier
    static func clearAllKeychainStore(service: String, accessGroup: String?) {
        // Initiate old stores, and delete all items
        let oldPrivateStore = KeychainService(service: service + KeychainStoreType.local.rawValue)
        oldPrivateStore.deleteAll()
        if let accessGroup = accessGroup, KeychainService.validateAccessGroup(service: service, accessGroup: accessGroup) {
          let oldSharedStore = KeychainService(service: service + KeychainStoreType.shared.rawValue, accessGroup: accessGroup)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup)
          oldCookieStore.deleteAll()
        }
        else {
          let oldSharedStore = KeychainService(service: service + KeychainStoreType.shared.rawValue)
          oldSharedStore.deleteAll()
          let oldCookieStore = KeychainService(service: service + KeychainStoreType.cookie.rawValue)
          oldCookieStore.deleteAll()
        }
    }
}
