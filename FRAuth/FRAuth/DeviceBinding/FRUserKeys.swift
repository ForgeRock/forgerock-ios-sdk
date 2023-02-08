// 
//  FRUserKeys.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Manage ``UserKey``s  that are created by the SDK. The ``UserKey``s are created with ``DeviceBindingCallback``
struct FRUserKeys {
    private var userKeyService: UserKeyService
    
    /// FRUserKeys initizializer
    /// - Parameter userKeyService: default value is ``UserDeviceKeyService()``
    init(userKeyService: UserKeyService = UserDeviceKeyService()) {
        self.userKeyService = userKeyService
    }
    
    /// Load all the ``UserKey``s  that are created with ``DeviceBindingCallback``
    func loadAll() -> [UserKey] {
        return userKeyService.getAll()
    }
    
    /// Delete the ``UserKey``
    /// - Parameter userKey: the ``UserKey`` to be deleted
    func delete(userkey: UserKey) {
        userKeyService.delete(userKey: userkey)
    }
}
