//
//  FRAppIntegrityDomainModal.swift
//  FRAuth
//
//  Copyright (c) 2023 - 2024 ForgeRock. All rights reserved.
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
    /// - Parameter challenge: challenge Received from server
    /// - Parameter payload: payload to be signed
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys for attestation and assertion
    func requestIntegrityToken(challenge: String,
                               payload: String?) async throws -> FRAppIntegrityKeys
        
}

/// Attestation modal to fetch the result for the given callback
@available(iOS 14.0, *)
struct FRAppAttestDomainModal: FRAppAttestation {
    
    private let service: FRAppAttestService
    private let bundleIdentifier: String?
    private let encoder: JSONEncoder
    private var appIntegrityKeys: FRAppIntegrityKeys
    private let challengeKey = "challenge"
    private let bundleIdKey = "bundleId"
    private let payloadKey = "payload"
    private let delimiter = "::";
    
    // Create a static property to hold the shared instance
    static var shared: FRAppAttestation = {
        return FRAppAttestDomainModal()
    }()
    
    
    // MARK: - Init
    
    /// Initializes FRAppAttestDomainModal
    ///
    /// - Parameter service: FRAppAttestService to connect AppAttestation server
    /// - Parameter appIntegrityKeys: FRAppIntegrityKeys to fetch the keys result
    /// - Parameter bundleIdentifier: BundleId of the application
    /// - encoder encoder: Encoder to encode the Data
    init(service: FRAppAttestService = FRAppAttestServiceImpl(),
         appIntegrityKeys: FRAppIntegrityKeys = FRAppIntegrityKeys(),
         bundleIdentifier: String? = Bundle.main.bundleIdentifier,
         encoder: JSONEncoder = JSONEncoder()) {
        self.service = service
        self.bundleIdentifier = bundleIdentifier
        self.encoder = encoder
        self.appIntegrityKeys = appIntegrityKeys
    }
    
    /// Handle attestation and assertion
    /// - Parameter challenge: challenge Received from server
    /// - Parameter payload: payload to be signed
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys for attestation and assertion
    func requestIntegrityToken(challenge: String,
                               payload: String? = nil) async throws -> FRAppIntegrityKeys {
        do {
            let result = try validate(challenge: challenge, payload: payload)
            guard let unwrapIdentifier = self.appIntegrityKeys.getKey() else {
                return try await attestation(challenge: result.0, jsonData: result.1)
            }
            FRLog.i("AppIntegrityCallback::Key already exist, Do assertion")
            let seperatedObject = unwrapIdentifier.components(separatedBy: delimiter)
            if seperatedObject.count > 1 {
                let keyId = seperatedObject[0]
                let attestation = seperatedObject[1]
                return try await assertion(challenge: result.0,
                                           jsonData: result.1,
                                           keyIdValue: keyId,
                                           attestationValue: attestation)
            } else {
                FRLog.e("AppIntegrityCallback::KeyChain value is nil/Empty and the key exist")
                throw FRDeviceCheckAPIFailure.keyChainError
            }
        }
        catch let error as DCError {
            throw FRDeviceCheckAPIFailure.error(code: error.errorCode)
        }
        catch {
            throw error
        }
    }
    
    /// Handle validation
    ///
    /// - Parameter challenge: challenge Received from server
    /// - Parameter payload: payload to be signed
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: challenge and userClientData
    private func validate(challenge: String,
                          payload: String? = nil) throws -> (Data, Data) {
        
        if !service.isSupported() {
            throw FRDeviceCheckAPIFailure.featureUnsupported
        }
        
        guard let bundleIdentifier = bundleIdentifier, !bundleIdentifier.isEmpty else {
            throw FRDeviceCheckAPIFailure.invalidBundleIdentifier
        }
        
        guard let challengeUtf8 = challenge.data(using: .utf8), !challengeUtf8.isEmpty else {
            throw FRDeviceCheckAPIFailure.invalidChallenge
        }
        
        let userClientData = [challengeKey: challenge,
                               bundleIdKey: bundleIdentifier,
                                payloadKey: payload ?? ""]
        
        guard let jsonData = try? encoder.encode(userClientData) else {
            throw FRDeviceCheckAPIFailure.invalidClientData
        }
        
        return (challengeUtf8, jsonData)
        
    }
    
    /// attestation
    ///
    /// - Parameter challenge: challenge Received from server
    /// - Parameter jsonData: jsonData Received from server
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys
    private func attestation(challenge: Data,
                             jsonData: Data) async throws -> FRAppIntegrityKeys {
        let keyId = try await service.generateKey()
        let result = try await service.attest(keyIdentifier: keyId, clientDataHash: Data(SHA256.hash(data: challenge)))
        let attestation = result.base64EncodedString()
        return FRAppIntegrityKeys(attestKey: attestation,
                                  assertKey: nil,
                                  keyIdentifier: keyId,
                                  clientDataHash: jsonData.base64EncodedString())
    }
    
    /// assertion
    ///
    /// - Parameter challenge: challenge Received from server
    /// - Parameter jsonData: jsonData Received from server
    /// - Parameter keyIdValue: keyIdValue from keychain
    /// - Parameter attestationValue: attestationValue from keychain
    /// - Throws: `FRDeviceCheckAPIFailure and Error`
    /// - Returns: FRAppIntegrityKeys
    private func assertion(challenge: Data,
                           jsonData: Data,
                           keyIdValue: String,
                           attestationValue: String) async throws -> FRAppIntegrityKeys {
        do {
            let assertion = try await withRetry {
                try await service.generateAssertion(keyIdentifier: keyIdValue, clientDataHash: Data(SHA256.hash(data: jsonData))).base64EncodedString()
            }
            return FRAppIntegrityKeys(attestKey: attestationValue,
                                      assertKey: assertion,
                                      keyIdentifier: keyIdValue,
                                      clientDataHash: jsonData.base64EncodedString())
            
        } catch {
            FRLog.e("AppIntegrityCallback::Error Recovering \(error.localizedDescription)")
            self.appIntegrityKeys.deleteKey()
            return try await attestation(challenge: challenge, jsonData: jsonData)
        }
        
    }
    
    /// withRetry
    ///
    /// - Parameter maxRetries: Challenge Received from server
    /// - Parameter operation: execute the operation
    /// - Throws: `Error`
    /// - Returns: T genric operation
    private func withRetry<T>(maxRetries: Int = 2, operation: @escaping () async throws -> T) async throws -> T {
        var currentRetry = 0
        var lastError: Error = FRDeviceCheckAPIFailure.unknownError
        repeat {
            do {
                return try await operation()
            }
            catch {
                lastError = error
                currentRetry += 1
            }
        } while currentRetry < maxRetries
        throw lastError
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
    case keyChainError
    
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
