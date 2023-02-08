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
    
    func getAllKeys() -> [String: Any]?
}


/// Helper class to save and retrieve user keys
internal class KeychainDeviceRepository: DeviceRepository {
    static let keychainServiceIdentifier = "com.forgerock.ios.devicebinding.keychainservice"
    static let userIdKey = "userId"
    static let kidKey = "kid"
    static let authTypeKey = "authType"
    static let userNameKey = "username"
    static let createdAtKey = "createdAt"
    
    private var uuid: String = ""
    private var keychainService: KeychainService
    
    /// Initializes KeychainDeviceRepository with given uuid and keychainService
    /// - Parameter uuid: default value is `UUID().uuidString`
    /// - Parameter keychainService: default value is `FRAuth.shared?.keychainManager.sharedStore ?? KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier, securedKey: nil)`
    init(uuid: String? = nil, keychainService: KeychainService? = nil) {
        self.uuid = uuid ?? UUID().uuidString
        self.keychainService = keychainService ?? FRAuth.shared?.keychainManager.sharedStore ?? KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier, securedKey: nil)
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
        
        let dictionary: [String: Any] = [KeychainDeviceRepository.userIdKey: userId,
                                         KeychainDeviceRepository.userNameKey: userName,
                                         KeychainDeviceRepository.kidKey: uuid,
                                         KeychainDeviceRepository.authTypeKey: authenticationType.rawValue,
                                         KeychainDeviceRepository.createdAtKey: createdAt]
        
        let data = try JSONSerialization.data(withJSONObject: dictionary)
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
