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
    
    
    public func generateAppAttestKey(completion: @escaping (String) -> Void) {
        
        self.keyChainManager?.privateStore.set(nil, key: self.keyName)
    
        // The generateKey method returns an ID associated with the key.  The key itself is stored in the Secure Enclave
        dcAppAttestService.generateKey(completionHandler: { keyId, error in

            guard let attestKeyId = keyId else {
                print("key generate failed: \(String(describing: error))")
                return
            }
            
//            // we check this
//            self.keyChainManager?.privateStore.getString(self.keyName)
            
            self.keyChainManager?.privateStore.set(attestKeyId, key: self.keyName)
            
            completion(attestKeyId)
            
        })
    }
    
    public func verifyAssertion(challenge: String = "1234") {
        
        guard let keyId = keyChainManager?.privateStore.getString(keyName) else {
                return
        }
        
        
        let clientData = Data(SHA256.hash(data: challenge.data(using: .utf8)!))
        //let clientDataHash = Data(SHA256.hash(data: clientData))
        
        DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientData) { assertion, error in
            guard error == nil else {
                print ("ERROR: Assertion not available right now")
                return
            }
            // create assertion request
            var urlRequest = URLRequest(url: URL(string: "http://192.168.1.93:8090/users/verify4J")!)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let clientDataString = clientData.base64EncodedString()
            let assertionString = assertion!.base64EncodedString()
            let assertRequest: [String: Any] = ["userdata": clientDataString, "assertionObject": assertionString, "keyIdBase64": keyId]
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: assertRequest, options: [])
                urlRequest.httpBody = jsonData
            } catch {
                print (error)
                return
            }
            
            // send assertion request to server
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                guard error == nil else {
                    // request sending failed, try again later
                    print (error!)
                    return
                }
                
                print(data)
            }
            task.resume()
        }
    }
    
    // may be this challenge comes from server
    public func certifyAppAttestKey(challenge: String = "1234") {
        
        generateAppAttestKey(completion: { keyId in
            
       // let keyId = "nydIR7caes6XY+pcDV1v2/3jNKw8Zq/ygMjOTN+WRBQ="
        
        let hashValue = Data(SHA256.hash(data: challenge.data(using: .utf8)!))
        
//        let requestJSON = "{'sessionId': '\(challenge)'}".data(using: .utf8)!
//        let hashValue = Data(SHA256.hash(data: requestJSON))
        
        // This method contacts Apple's server to retrieve an attestation object for the given hash value
            self.dcAppAttestService.attestKey(keyId, clientDataHash: hashValue) { attestation, error in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }

            guard let attestation = attestation?.base64EncodedString() else {
                return
            }
            
            let dict = [
                "attestationObject": attestation,
                "keyIdBase64": keyId,
            ]

            var jsonData: Data?
            do {
                jsonData = try JSONEncoder().encode(dict)
            } catch {
                return
            }
            

            // send to application server to complete attestation
            let url = URL(string: "http://192.168.1.93:8090/users/attest4J")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

            let session = URLSession.shared
            let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
                
                print(error)
                print(data)
                print(response)
                
            
                // add success/error handling here
            }
            task.resume()
        }
        })
    }
}

