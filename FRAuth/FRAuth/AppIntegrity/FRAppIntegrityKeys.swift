//
//  FRAppAuthKeys.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// FRAppIntegrityKeys entity or datamodel which stores all the AppAttesation keys information
public struct FRAppIntegrityKeys {
    
    public private(set) var appAttestKey: String
    public private(set) var assertKey: String? = nil
    public private(set) var keyIdentifier: String
    public private(set) var clientDataHash: String
    private let key = "com.forgerock.ios.appattest.keychainservice"
    private let keychain: KeychainManager? = FRAuth.shared?.keychainManager
    
    // MARK: - Init
    
    /// Initializes FRAppAttestDomainModal
    ///
    /// - Parameter attestKey: key generated from apple server
    /// - Parameter assertKey: key generated from secureEnclave
    /// - Parameter keyIdentifier: key alias for public/privekey
    /// - Parameter clientDataHash: BundleId/challenge of the application
    public init(attestKey: String = String(),
                assertKey: String? = nil,
                keyIdentifier: String = String(),
                clientDataHash: String = String()) {
        self.appAttestKey = attestKey
        self.assertKey = assertKey
        self.keyIdentifier = keyIdentifier
        self.clientDataHash = clientDataHash
    }
    
    internal func updateKey(value: String) {
        self.keychain?.privateStore.set(value, key: key)
    }
    
    internal func getKey() -> String? {
        return self.keychain?.privateStore.getString(key)
    }
    
    /// verify the attestation completed or not
    /// - Returns: true or false if the attestation key exist
    public func isAttestationCompleted() -> Bool {
        return self.getKey() != nil
    }
    
    /// Delete the attestation key reference from keychain
    public func deleteKey() {
        self.keychain?.privateStore.delete(key)
    }
    
}
