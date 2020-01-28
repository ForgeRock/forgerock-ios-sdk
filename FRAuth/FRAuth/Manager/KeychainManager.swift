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

struct KeychainManager {

    enum KeychainStoreType: String {
        case local = ".local"
        case shared = ".shared"
        case cookie = ".cookie"
        case deviceIdentifier = ".deviceIdentifierService"
    }
    
    var accessGroup: String?
    var privateStore: KeychainService
    var sharedStore: KeychainService
    var cookieStore: KeychainService
    var deviceIdentifierStore: KeychainService
    var primaryServiceStore: KeychainService
    var isSharedKeychainAccessible: Bool = false
    
    public init?(baseUrl: String, accessGroup: String? = nil, enableCookie: Bool = true) throws {
        
        // Define currentService based on primary server
        let service = "com.forgerock.ios.keychainservice"
        let currentService = baseUrl + "/" + service
        self.primaryServiceStore = KeychainService(service: service)
        
        // If primaryService currently stored is different from what's passed through parameter
        if self.primaryServiceStore.getString("primaryService") == nil {
            FRLog.i("Creating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: "primaryService")
        } else if let previousService = self.primaryServiceStore.getString("primaryService"), currentService != previousService{
            
            FRLog.i("Detected different primary server URL; clearing credentials for previous server")
            // Initiate old stores, and delete all items
            let oldPrivateStore = KeychainService(service: previousService + KeychainStoreType.local.rawValue)
            oldPrivateStore.deleteAll()
            if let accessGroup = accessGroup, KeychainService.validateAccessGroup(service: previousService, accessGroup: accessGroup) {
                let oldSharedStore = KeychainService(service: previousService + KeychainStoreType.shared.rawValue, accessGroup: accessGroup)
                oldSharedStore.deleteAll()
                let oldCookieStore = KeychainService(service: previousService + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup)
                oldCookieStore.deleteAll()
            }
            else {
                let oldSharedStore = KeychainService(service: previousService + KeychainStoreType.shared.rawValue)
                oldSharedStore.deleteAll()
                let oldCookieStore = KeychainService(service: previousService + KeychainStoreType.cookie.rawValue)
                oldCookieStore.deleteAll()
            }
            
            FRLog.i("Updating primary keychain service dedicated to \(baseUrl)")
            self.primaryServiceStore.set(currentService, key: "primaryService")
        }
        
        
        if let accessGroup = accessGroup {
            // If Access Group was provided, construct KeychainService with Access Group
            self.accessGroup = accessGroup
            
            // Validate whether given Access Group is accessible or not
            if KeychainService.validateAccessGroup(service: currentService, accessGroup: accessGroup) {
                self.privateStore = KeychainService(service: currentService + KeychainStoreType.local.rawValue)
                self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue, accessGroup: accessGroup)
                self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue, accessGroup: accessGroup)
                
                // Constructs Device Identifier storage with specific Keychain Options
                var option = KeychainOptions(service: service + KeychainStoreType.deviceIdentifier.rawValue, accessGroup: accessGroup)
                option.accessibility = .alwaysThisDeviceOnly
                self.deviceIdentifierStore = KeychainService(options: option)
                
                self.isSharedKeychainAccessible = true
            }
            else {
                throw ConfigError.invalidAccessGroup(accessGroup)
            }
        }
        else {
            // If Access Group is not provided, construct KeychainService without Access Group
            self.privateStore = KeychainService(service: currentService + KeychainStoreType.local.rawValue)
            self.sharedStore = KeychainService(service: currentService + KeychainStoreType.shared.rawValue)
            self.cookieStore = KeychainService(service: currentService + KeychainStoreType.cookie.rawValue)
            
            // Constructs Device Identifier storage with specific Keychain Options
            var option = KeychainOptions(service: service + KeychainStoreType.deviceIdentifier.rawValue)
            option.accessibility = .alwaysThisDeviceOnly
            self.deviceIdentifierStore = KeychainService(options: option)
        }
        
        if !enableCookie {
            FRLog.i("'forgerock_enable_cookie' value was set to false; deleting all cookies from Cookie Store.")
            self.cookieStore.deleteAll()
        }
    }
}
