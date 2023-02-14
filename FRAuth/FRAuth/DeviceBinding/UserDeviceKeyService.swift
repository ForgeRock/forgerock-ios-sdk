// 
//  UserDeviceKeyService.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
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
    func getAll() -> [UserKey]
    
    
    /// Delete user key
    func delete(userKey: UserKey)
}


internal class UserDeviceKeyService: UserKeyService {
    private var deviceRepository: DeviceRepository
    
    
    /// Initializes ``UserDeviceKeyService`` with given ``DeviceRepository``
    /// - Parameter deviceRepository: default value is ``KeychainDeviceRepository()``
    init(deviceRepository: DeviceRepository = KeychainDeviceRepository()) {
        self.deviceRepository = deviceRepository
    }
    
    
    /// Get all the user keys in device.
    func getAll() -> [UserKey] {
        return deviceRepository.getAllKeys()?.compactMap { (key, value) -> UserKey? in
            guard let data = (value as? String)?.data(using: .utf8),
               let userKey = try? JSONDecoder().decode(UserKey.self, from: data) else {
                return nil
            }
            return userKey
        } ?? [UserKey]()
    }
    
    
    /// Fetch the key existence status in device.
    /// - Parameter  userId: optional and received from server
    func getKeyStatus(userId: String?) -> KeyFoundStatus {
        let userKeys = getAll()
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
    
    
    /// Delete user key
    /// - Parameter userkey: ``UserKey`` to be deleted
    func delete(userKey: UserKey) {
        let _ = deviceRepository.delete(key: userKey.keyAlias)
        let authInterface = userKey.authType.getAuthType()
        authInterface.initialize(userId: userKey.userId)
        authInterface.deleteKeys()
    }
    
}


public enum KeyFoundStatus {
    case singleKeyFound(key: UserKey)
    case multipleKeysFound(keys: [UserKey])
    case noKeysFound
}


public struct UserKey: Equatable, Codable {
    var userId: String
    var userName: String
    var kid: String
    var authType: DeviceBindingAuthenticationType
    var keyAlias: String
    var createdAt: Double
}
