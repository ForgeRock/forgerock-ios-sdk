//
//  FRAppIntegrityService.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import DeviceCheck

/// Protocol to assert the legitimacy of a particular instance of your app to your server.
@available(iOS 14.0, *)
protocol FRAppAttestService {
    /// Creates a new cryptographic key for use with the App Attest service.
    /// - Returns: KeyId An identifier that you use to refer to the key. The framework securely
    /// stores the key in the Secure Enclave.
    /// - Throws: `DCError`
    func generateKey() async throws -> String
    /// Asks Apple to attest to the validity of a generated cryptographic key.
    ///
    /// - Parameters:
    ///   - keyIdentifier: The identifier you received when generating a cryptographic key by calling the generateKey(completionHandler:) method.
    ///   - clientDataHash: A SHA256 hash of a unique, single-use data block that embeds a challenge from your server.
    ///   - Throws: `DCError`
    /// - Returns: A statement from Apple about the validity of the key associated with keyId. Send this to your server for processing OR DCError instance that indicates the reason for failure, or nil on success.
    func attest(keyIdentifier: String, clientDataHash: Data) async throws -> Data
    /// Creates a block of data that demonstrates the legitimacy of an instance of your app running on a device.
    ///
    /// - Parameters:
    ///   - keyIdentifier: The identifier you received when generating a cryptographic key by calling the generateKey(completionHandler:) method.
    ///   - clientDataHash: A SHA256 hash of a unique, single-use data block that represents the client data to be signed with the attested private key.
    ///   - Throws: `DCError`
    /// - Returns: A data structure that you send to your server for processing OR A DCError instance that indicates the reason for failure, or nil on success.
    func generateAssertion(keyIdentifier: String, clientDataHash: Data) async throws -> Data
    /// Not all device types support the App Attest service, so check for support
    /// before using the service.
    /// - Returns: A Boolean value that indicates whether a particular device provides the App Attest service.
    func isSupported() -> Bool
}

/// Attestation service  wrapper directly communicates to DeviceCheck server
@available(iOS 14.0, *)
struct FRAppAttestServiceImpl: FRAppAttestService {
    
    private let dcAppAttestService: DCAppAttestService
    
    /// The service that you use to validate the instance of your app running on a device.
    ///
    /// - Parameters:
    ///   - service: The shared App Attest service that you use to validate your app.
    init(service: DCAppAttestService = DCAppAttestService.shared) {
        self.dcAppAttestService = service
    }
    
    /// Not all device types support the App Attest service, so check for support
    /// before using the service.
    /// - Returns: A Boolean value that indicates whether a particular device provides the App Attest service.
    func isSupported() -> Bool {
        return dcAppAttestService.isSupported
    }
    
    /// Creates a new cryptographic key for use with the App Attest service.
    /// - Returns: KeyId An identifier that you use to refer to the key. The framework securely
    /// stores the key in the Secure Enclave.
    /// - Throws: `DCError`
    func generateKey() async throws -> String {
        return try await dcAppAttestService.generateKey()
    }
    
    /// Asks Apple to attest to the validity of a generated cryptographic key.
    ///
    /// - Parameters:
    ///   - keyIdentifier: The identifier you received when generating a cryptographic key by calling the generateKey(completionHandler:) method.
    ///   - clientDataHash: A SHA256 hash of a unique, single-use data block that embeds a challenge from your server.
    ///   - Throws: `DCError`
    /// - Returns: A statement from Apple about the validity of the key associated with keyId. Send this to your server for processing OR DCError instance that indicates the reason for failure, or nil on success.
    func attest(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        return try await dcAppAttestService.attestKey(keyIdentifier, clientDataHash: clientDataHash)
    }
    
    /// Creates a block of data that demonstrates the legitimacy of an instance of your app running on a device.
    ///
    /// - Parameters:
    ///   - keyIdentifier: The identifier you received when generating a cryptographic key by calling the generateKey(completionHandler:) method.
    ///   - clientDataHash: A SHA256 hash of a unique, single-use data block that represents the client data to be signed with the attested private key.
    ///   - Throws: `DCError`
    /// - Returns: A data structure that you send to your server for processing OR A DCError instance that indicates the reason for failure, or nil on success.
    func generateAssertion(keyIdentifier: String, clientDataHash: Data) async throws -> Data {
        return try await dcAppAttestService.generateAssertion(keyIdentifier, clientDataHash: clientDataHash)
    }
}


