// 
//  UserDeviceKeyService.swift
//  FRDeviceBinding
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
    func delete(userKey: UserKey, forceDelete: Bool) throws
}


internal class UserDeviceKeyService: UserKeyService {
    private var localDeviceBindingRepository: DeviceBindingRepository
    private var remoteDeviceBindingRepository: DeviceBindingRepository
    
    /// Initializes ``UserDeviceKeyService``
    /// - Parameter localDeviceBindingRepository: default value is ``LocalDeviceBindingRepository()``
    /// - Parameter remoteDeviceBindingRepository: default value is ``RemoteDeviceBindingRepository()``
    init(localDeviceBindingRepository: DeviceBindingRepository = LocalDeviceBindingRepository(),
         remoteDeviceBindingRepository: DeviceBindingRepository = RemoteDeviceBindingRepository()) {
        self.localDeviceBindingRepository = localDeviceBindingRepository
        self.remoteDeviceBindingRepository = remoteDeviceBindingRepository
    }
    
    
    /// Get all the user keys in device.
    func getAll() -> [UserKey] {
        return localDeviceBindingRepository.getAllKeys()
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
    /// - Parameter forceDelete: Defaults to false, true will delete local keys even if the server key removal has failed
    func delete(userKey: UserKey, forceDelete: Bool = false) throws {
        do {
            try remoteDeviceBindingRepository.delete(userKey: userKey)
            deleteLocal(userKey: userKey)
        } catch let error {
            if forceDelete {
                deleteLocal(userKey: userKey)
            }
            throw error
        }
    }
    
    
    private func deleteLocal(userKey: UserKey) {
        let _ = try? localDeviceBindingRepository.delete(userKey: userKey)
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
    public var id: String
    public var userId: String
    public var userName: String
    public var kid: String
    public var authType: DeviceBindingAuthenticationType
    public var createdAt: Double
}
