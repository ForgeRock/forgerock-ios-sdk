// 
//  AppAttest.swift
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
import FRCore

@available(iOS 14.0, *)
public class AppAttest {
    private let keyName = "appAttestKey"
    private let dcAppAttestService = DCAppAttestService.shared
    
    // And given invalid Keychain Service with inaccessible AccessGroup
    var keyChainManager: KeychainManager? = FRAuth.shared?.keychainManager
    
    public init () {}
    
    public func getAppAttestKeyId() -> String? {
         
         guard let keyId = keyChainManager?.privateStore.getString(keyName) else {
            generateAppAttestKey()
            return nil
        }

        return keyId
    }
    
    public func generateAppAttestKey() {
        // The generateKey method returns an ID associated with the key.  The key itself is stored in the Secure Enclave
        dcAppAttestService.generateKey(completionHandler: { keyId, error in

            guard let attestKeyId = keyId else {
                print("key generate failed: \(String(describing: error))")
                return
            }
            
            self.keyChainManager?.privateStore.set(attestKeyId, key: self.keyName)

        })
    }
    
    // may be this challenge comes from server
    public func certifyAppAttestKey(challenge: String) {
        guard let keyId = getAppAttestKeyId() else {
            return
        }

        let hashValue = Data(SHA256.hash(data: challenge.data(using: .utf8) ?? Data()))

        // This method contacts Apple's server to retrieve an attestation object for the given hash value
        dcAppAttestService.attestKey(keyId, clientDataHash: hashValue) { attestation, error in
            guard error == nil else {
                return
            }

            guard let attestation = attestation else {
                return
            }

            // send to application server to complete attestation
            let url = URL(string: "http://192.168.1.30:5000/attest")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

            let session = URLSession.shared
            let task = session.uploadTask(with: request, from: attestation) { data, response, error in
                // add success/error handling here
            }
            task.resume()
        }
    }
    
}

