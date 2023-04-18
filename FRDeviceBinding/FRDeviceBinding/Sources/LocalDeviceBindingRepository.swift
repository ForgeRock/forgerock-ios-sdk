// 
//  LocalDeviceBindingRepository.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore
import FRAuth

protocol DeviceBindingRepository {
    
    /// Persist userKey in encrypted storage
    func persist(userKey: UserKey) throws
    
    /// Get all userKeys
    func getAllKeys() -> [UserKey]
    
    /// Delete the userKey
    func delete(userKey: UserKey) throws
}


/// Helper class to save and retrieve user keys
internal class LocalDeviceBindingRepository: DeviceBindingRepository {
    
    static let keychainServiceIdentifier = "com.forgerock.ios.devicebinding.keychainservice"
    private var keychainService: KeychainService
    
    /// Initializes LocalDeviceBindingRepository with given keychainService
    /// - Parameter keychainService: default value is `KeychainService(service: LocalDeviceBindingRepository.keychainServiceIdentifier, accessGroup: accessGroup)`
    init(keychainService: KeychainService? = nil) {
        guard let keychainService = keychainService else {
            if let accessGroup = FRAuth.shared?.options?.keychainAccessGroup {
                self.keychainService = KeychainService(service: LocalDeviceBindingRepository.keychainServiceIdentifier, accessGroup: accessGroup)
            } else {
                self.keychainService = KeychainService(service: LocalDeviceBindingRepository.keychainServiceIdentifier)
            }
            return
        }
        
        self.keychainService = keychainService
    }
    
    
    /// Persist userkey in encrypted storage
    /// - Parameter userKey: userKey to be persisted
    func persist(userKey: UserKey) throws {
        let data = try JSONEncoder().encode(userKey)
        let str = String(decoding: data, as: UTF8.self)
        keychainService.set(str, key: userKey.id)
    }
    
    
    /// Get all keys stored in keychain
    func getAllKeys() -> [UserKey] {
        return keychainService.allItems()?.compactMap { (key, value) -> UserKey? in
            guard let data = (value as? String)?.data(using: .utf8),
                  let userKey = try? JSONDecoder().decode(UserKey.self, from: data) else {
                return nil
            }
            return userKey
        } ?? [UserKey]()
    }
    
    
    /// Delete given userKey
    func delete(userKey: UserKey) {
        keychainService.delete(userKey.id)
    }
    
    
    /// Delete all user keys
    func deleteAllKeys() -> Bool {
        return keychainService.deleteAll()
    }
}
