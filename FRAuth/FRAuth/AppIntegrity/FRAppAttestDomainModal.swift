//
//  FRAppIntegrityDomainModal.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CryptoKit
import DeviceCheck

/// Protocol to override attestation
@available(iOS 14.0, *)
public protocol FRAppAttestation {
    /// Handle attestation and assertion
    /// - Parameter challenge: Challenge Received from server
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys for attestation and assertion
    func attest(challenge: String) async throws -> FRAppIntegrityKeys
}

/// Attestation modal to fetch the result for the given callback
@available(iOS 14.0, *)
struct FRAppAttestDomainModal: FRAppAttestation {
    
    private let service: FRAppAttestService
    private let bundleIdentifier: String?
    private let encoder: JSONEncoder
    private let challengeKey = "challenge"
    private let bundleIdKey = "bundleId"
    
    // Create a static property to hold the shared instance
    static var shared: FRAppAttestation = {
        return FRAppAttestDomainModal()
    }()
    
    
    // MARK: - Init
    
    /// Initializes FRAppAttestDomainModal
    ///
    /// - Parameter service: FRAppAttestService to connect AppAttestation server
    /// - Parameter bundleIdentifier: BundleId of the application
    /// - encoder encoder: Encoder to encode the Data
    init(service: FRAppAttestService = FRAppAttestServiceImpl(),
         bundleIdentifier: String? = Bundle.main.bundleIdentifier,
         encoder: JSONEncoder = JSONEncoder()) {
        self.service = service
        self.bundleIdentifier = bundleIdentifier
        self.encoder = encoder
    }
    
    /// Handle attestation and assertion
    /// - Parameter challenge: Challenge Received from server
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys for attestation and assertion
    func attest(challenge: String) async throws -> FRAppIntegrityKeys {
        guard let challengeUtf8 = challenge.data(using: .utf8), !challengeUtf8.isEmpty else {
            throw FRDeviceCheckAPIFailure.invalidChallenge
        }
        guard let bundleIdentifier = bundleIdentifier, !bundleIdentifier.isEmpty else {
            throw FRDeviceCheckAPIFailure.invalidBundleIdentifier
        }
        let userClientData = [challengeKey: challenge,
                               bundleIdKey: bundleIdentifier]
        
        guard let jsonData = try? encoder.encode(userClientData) else {
            throw FRDeviceCheckAPIFailure.invalidClientData
        }
        
        if !service.isSupported() {
            throw FRDeviceCheckAPIFailure.featureUnsupported
        }
        
        do {
            let keyIdentifier = try await service.generateKey()
            let attest = try await service.attest(keyIdentifier: keyIdentifier, clientDataHash: Data(SHA256.hash(data: challengeUtf8)))
            let assert = try await service.generateAssertion(keyIdentifier: keyIdentifier, clientDataHash: Data(SHA256.hash(data: jsonData)))
            return FRAppIntegrityKeys(attestKey: attest.base64EncodedString(),
                                      assertKey: assert.base64EncodedString(),
                                      keyIdentifier: keyIdentifier,
                                      clientDataHash: jsonData.base64EncodedString())
        }
        catch let error as DCError {
            throw FRDeviceCheckAPIFailure.error(code: error.errorCode)
        }
        catch {
            throw error
        }
    }
    
}

/// Results of AppIntegrity Failures
/// We need to return some of failures for iOS12, iOS13 devices as well.
public enum FRDeviceCheckAPIFailure: String, Error {
    case unknownSystemFailure
    case featureUnsupported
    case invalidInput
    case invalidKey
    case serverUnavailable
    case invalidChallenge
    case invalidBundleIdentifier
    case invalidClientData
    case unknownError
    
    var clientError: String {
        switch self {
        case FRDeviceCheckAPIFailure.featureUnsupported:
            return FRAppIntegrityClientError.unSupported.rawValue
        default:
            return FRAppIntegrityClientError.clientDeviceErrors.rawValue
        }
    }
    
    static func error(code: Int) -> FRDeviceCheckAPIFailure {
        switch code {
        case DCError.unknownSystemFailure.rawValue:
            return .unknownSystemFailure
        case DCError.featureUnsupported.rawValue:
            return .featureUnsupported
        case DCError.invalidInput.rawValue:
            return .invalidInput
        case DCError.invalidKey.rawValue:
            return .invalidKey
        case DCError.serverUnavailable.rawValue:
            return .serverUnavailable
        default:
            return .unknownError
        }
    }
}

/// List of clientErrors sent to AM
public enum FRAppIntegrityClientError: String {
    case unSupported = "Unsupported"
    case clientDeviceErrors = "ClientDeviceErrors"
}

/// Result of Attestaion and Assertion keys that needs to send to server
@available(iOS 14.0, *)
public struct FRAppIntegrityKeys {
    let attestKey: String
    let assertKey: String
    let keyIdentifier: String
    let clientDataHash: String
}

