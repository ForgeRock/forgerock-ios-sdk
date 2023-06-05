// 
//  FRUserKeys.swift
//  FRDeviceBinding
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// Manage ``UserKey``s  that are created by the SDK. The ``UserKey``s are created with ``DeviceBindingCallback``
public struct FRUserKeys {
    private var userKeyService: UserKeyService
    
    /// FRUserKeys initizializer
    public init() {
        self.init(userKeyService: UserDeviceKeyService())
    }
    
    /// FRUserKeys initizializer
    /// - Parameter userKeyService: default value is ``UserDeviceKeyService()``
    init(userKeyService: UserKeyService) {
        self.userKeyService = userKeyService
    }
    
    /// Load all the ``UserKey``s  that are created with ``DeviceBindingCallback``
    public func loadAll() -> [UserKey] {
        return userKeyService.getAll()
    }
    
    /// Delete the ``UserKey``
    /// - Parameter userKey: the ``UserKey`` to be deleted
    /// - Parameter forceDelete:  Defaults to false, true will delete local keys even if the server key removal has failed
    public func delete(userKey: UserKey, forceDelete: Bool = false) throws {
        try userKeyService.delete(userKey: userKey, forceDelete: forceDelete)
    }
}
