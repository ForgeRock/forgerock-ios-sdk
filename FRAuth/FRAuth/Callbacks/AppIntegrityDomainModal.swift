// 
//  AppIntegrityDomainModal.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import DeviceCheck
import CryptoKit

@available(iOS 14.0, *)
class AppIntegrityDomainModal {
    
    private let dcAppAttestService: DCAppAttestService
    private let keyChainManager: KeychainManager?
    private let keyName = "appAttestKeyIdentifier"
    
    init(service: DCAppAttestService = DCAppAttestService.shared, keyChainManager: KeychainManager? = FRAuth.shared?.keychainManager) {
        self.dcAppAttestService = service
        self.keyChainManager = keyChainManager
    }
    
    func getKeyIdentifier() -> String? {
        return keyChainManager?.privateStore.getString(keyName)
    }
   
    func generateKey() async throws -> String {
        let keyIdentifier = try await dcAppAttestService.generateKey()
        self.keyChainManager?.privateStore.set(keyIdentifier, key: self.keyName)
        return keyIdentifier
    }
    
    func attest(challenge: String, keyIdentifier: String) async throws -> String {
        guard let challengeUtf8 = challenge.data(using: .utf8) else {
            throw AppIntegrityModalResult.invalidChallenge
        }
        let hashValue = Data(SHA256.hash(data: challengeUtf8))
        let attestKey = try await dcAppAttestService.attestKey(keyIdentifier, clientDataHash: hashValue)
        return attestKey.base64EncodedString()
    }
    
    func assert(challenge: String, keyIdentifier: String) async throws -> (String, String) {
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            throw AppIntegrityModalResult.invalidBundleIdentifier
        }
      
        let userClientData = ["challenge": challenge, "bundleId": bundleIdentifier]
        
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(userClientData) else {
            throw AppIntegrityModalResult.invalidClientData
        }
        
        let clientDataHash = Data(SHA256.hash(data: jsonData))
        
        let assertKey = try await dcAppAttestService.generateAssertion(keyIdentifier, clientDataHash: clientDataHash)
        return (assertKey.base64EncodedString(), jsonData.base64EncodedString())
    }
    
}
// Results of AppIntegrity Failures
@available(iOS 14.0, *)
public enum AppIntegrityModalResult: Error {
    case invalidChallenge
    case invalidBundleIdentifier
    case invalidClientData
}
