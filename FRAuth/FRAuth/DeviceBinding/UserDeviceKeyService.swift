// 
//  UserDeviceKeyService.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


public protocol UserKeyService {
    
    /// Fetch the key existence status in device.
    /// - Parameter  userId: optional and received from server
    func getKeyStatus(userId: String?) -> KeyFoundStatus
    
    
    /// Get all the user keys in device.
    var userKeys: [UserKey] { get set }
}


internal class UserDeviceKeyService: UserKeyService {
    private var encryptedPreference: DeviceRepository
    var userKeys: [UserKey] = []
    
    
    /// Initializes SharedPreferencesDeviceRepository with given uuid and keychainService
    /// - Parameter uuid: set nil for default value
    /// - Parameter keychainService: set nil for default value
    init(encryptedPreference: DeviceRepository?) {
        self.encryptedPreference = encryptedPreference ?? SharedPreferencesDeviceRepository(uuid: nil, keychainService: nil)
        getAllUsers()
    }
    
    
    /// Get all the user keys in device.
    private func getAllUsers() {
        encryptedPreference.getAllKeys()?.forEach({ (key, value) in
            
            if let data = (value as? String)?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let userId = json[SharedPreferencesDeviceRepository.userIdKey] as? String,
               let userName = json[SharedPreferencesDeviceRepository.userNameKey] as? String,
               let kid = json[SharedPreferencesDeviceRepository.kidKey] as? String,
               let authTypeString = json[SharedPreferencesDeviceRepository.authTypeKey] as? String,
               let authType = DeviceBindingAuthenticationType(rawValue: authTypeString) {
                let userKey = UserKey(userId: userId, userName: userName, kid: kid, authType: authType, keyAlias: key)
                userKeys.append(userKey)
            }
        })
    }
    
    
    /// Fetch the key existence status in device.
    /// - Parameter  userId: optional and received from server
    func getKeyStatus(userId: String?) -> KeyFoundStatus {
        if let userId = userId, !userId.isEmpty {
            let key = userKeys.first { $0.userId == userId }
            return key == nil ? .noKeysFound : .singleKeyFound(key: key!)
        }
        
        switch userKeys.count {
        case 0: return .noKeysFound
        case 1: return .singleKeyFound(key: userKeys.first!)
        default: return .multipleKeysFound(keys: userKeys)
        }
    }
    
}


public enum KeyFoundStatus {
    case singleKeyFound(key: UserKey)
    case multipleKeysFound(keys: [UserKey])
    case noKeysFound
}


public struct UserKey {
    var userId: String
    var userName: String
    var kid: String
    var authType: DeviceBindingAuthenticationType
    var keyAlias: String
}
