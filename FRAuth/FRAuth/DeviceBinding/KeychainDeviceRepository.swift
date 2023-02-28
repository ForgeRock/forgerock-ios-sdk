// 
//  KeychainDeviceRepository.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


protocol DeviceRepository {
    
    /// Persist user key in encrypted storage
    func persist(userId: String,
                 userName: String,
                 key: String,
                 authenticationType: DeviceBindingAuthenticationType,
                 createdAt: Double) throws -> String
    
    /// Get all keys
    func getAllKeys() -> [String: Any]?
    
    /// Delete the key
    func delete(key: String) -> Bool 
}


/// Helper class to save and retrieve user keys
internal class KeychainDeviceRepository: DeviceRepository {
    static let keychainServiceIdentifier = "com.forgerock.ios.devicebinding.keychainservice"
    
    private var keychainService: KeychainService
    
    /// Initializes KeychainDeviceRepository with given keychainService
    /// - Parameter keychainService: default value is `FRAuth.shared?.keychainManager.sharedStore ?? KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier, securedKey: nil)`
    init(keychainService: KeychainService? = nil) {
        guard let keychainService = keychainService else {
            if let accessGroup = FRAuth.shared?.options?.keychainAccessGroup {
                self.keychainService = KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier, accessGroup: accessGroup)
            } else {
                self.keychainService = KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier)
            }
            return
        }
        
        self.keychainService = keychainService
    }
    
    
    /// Persist the data in keychain
    /// - Parameter userId: user id to be persisted
    /// - Parameter userName: user name to be persisted
    /// - Parameter key: key to be persisted
    /// - Parameter authenticationType: authenticationType to be persisted
    /// - Returns : uuid of the key
    func persist(userId: String,
                 userName: String,
                 key: String,
                 authenticationType: DeviceBindingAuthenticationType,
                 createdAt: Double) throws -> String {
        let uuid = UUID().uuidString
        let userKey = UserKey(userId: userId, userName: userName, kid: uuid, authType: authenticationType, keyAlias: key, createdAt: createdAt)

        let data = try JSONEncoder().encode(userKey)
        if let str = String(data: data, encoding: .utf8) {
            keychainService.set(str, key: key)
        } else {
            throw NSError()
        }
        return uuid
    }
    
    
    /// Get all keys stored in keychain
    func getAllKeys() -> [String: Any]? {
        keychainService.allItems()
    }
    
    
    /// Delete user info for given key
    func delete(key: String) -> Bool {
        return keychainService.delete(key)
    }
    
    
    /// Delete all user keys
    func deleteAllKeys() -> Bool {
        return keychainService.deleteAll()
    }
}
