// 
//  KeychainDeviceRepository.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


protocol DeviceRepository {
    
    /// Persist the data in encrypted shared preference
    func persist(userId: String,
                 userName: String,
                 key: String,
                 authenticationType: DeviceBindingAuthenticationType) throws -> String
    
    func getAllKeys() -> [String: Any]?
}


/// Helper class to save and retrieve EncryptedMessage
internal class KeychainDeviceRepository: DeviceRepository {
    static let keychainServiceIdentifier = "com.forgerock.ios.devicebinding.keychainservice"
    static let userIdKey = "userId"
    static let kidKey = "kid"
    static let authTypeKey = "authType"
    static let userNameKey = "username"
    
    private var uuid: String = ""
    private var keychainService: KeychainService
    
    /// Initializes SharedPreferencesDeviceRepository with given uuid and keychainService
    /// - Parameter uuid: set nil for default value
    /// - Parameter keychainService: set nil for default value
    init(uuid: String?, keychainService: KeychainService?) {
        self.uuid = uuid ?? UUID().uuidString
        self.keychainService = keychainService ?? FRAuth.shared?.keychainManager.sharedStore ?? KeychainService(service: KeychainDeviceRepository.keychainServiceIdentifier, securedKey: nil)
    }
    
    
    /// Persist the data in encrypted shared preference
    /// - Parameter userId: user id to be persisted
    /// - Parameter userName: user name to be persisted
    /// - Parameter key: key to be persisted
    /// - Parameter authenticationType: authenticationType to be persisted
    /// - Returns : uuid of the key
    func persist(userId: String,
                 userName: String,
                 key: String,
                 authenticationType: DeviceBindingAuthenticationType) throws -> String {
        let dictionary = [KeychainDeviceRepository.userIdKey: userId,
                          KeychainDeviceRepository.userNameKey: userName,
                          KeychainDeviceRepository.kidKey: uuid,
                          KeychainDeviceRepository.authTypeKey: authenticationType.rawValue]
        let data = try JSONEncoder().encode(dictionary)
        if let str = String(data: data, encoding: .utf8) {
            keychainService.set(str, key: key)
        } else {
            throw NSError()
        }
        return uuid
    }
    
    
    /// Get all keys stored in
    func getAllKeys() -> [String: Any]? {
        keychainService.allItems()
    }
    
    
    /// Delete user info for given key
    func delete(key: String) -> Bool {
        return keychainService.delete(key)
    }
    
    
    /// Delete user info for given key
    func deleteAllKeys() -> Bool {
        return keychainService.deleteAll()
    }
}
