//
//  AppIntegrityCallback.swift
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
open class AppIntegrityCallback: MultipleValuesCallback {
    

    public private(set) var challenge: String
    /// The authentication type of the journey
    
    
    /// Device id input key in callback response
    private var token: String
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
    private var keyId: String
    
    private var challengeClientData: String
    
    private var appVerification: String
    
    var keyChainManager: KeychainManager? = FRAuth.shared?.keychainManager
    
    private let dcAppAttestService = DCAppAttestService.shared
    
    private let keyName = "appAttestKey"
    private let appAttestToken = "appAttestToken"
    
    public required init(json: [String : Any]) throws {
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]], let inputs = json[CBConstants.input] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        // parse outputs
        var outputDictionary = [String: Any]()
        for output in outputs {
            guard let outputName = output[CBConstants.name] as? String, let outputValue = output[CBConstants.value] else {
                throw AuthError.invalidCallbackResponse("Failed to parse output")
            }
            outputDictionary[outputName] = outputValue
        }
        
               guard let challenge = outputDictionary[CBConstants.challenge] as? String else {
            throw AuthError.invalidCallbackResponse("Missing challenge")
        }
        self.challenge = challenge
        
        //parse inputs
        var inputNames = [String]()
        for input in inputs {
            guard let inputName = input[CBConstants.name] as? String else {
                throw AuthError.invalidCallbackResponse("Failed to parse input")
            }
            inputNames.append(inputName)
        }
        
        guard let deviceIdKey = inputNames.filter({ $0.contains("IDToken1attest") }).first else {
            throw AuthError.invalidCallbackResponse("Missing deviceIdKey")
        }
        self.token = deviceIdKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains("IDToken1clientError") }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        guard let keyId = inputNames.filter({ $0.contains("IDToken1keyId") }).first else {
            throw AuthError.invalidCallbackResponse("Missing keyId")
        }
        self.keyId = keyId
        
        guard let appVerification = inputNames.filter({ $0.contains("IDToken1assert") }).first else {
            throw AuthError.invalidCallbackResponse("Missing appVerification")
        }
        self.appVerification = appVerification
        
        guard let challengeClientData = inputNames.filter({ $0.contains("IDToken1clientData") }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientData")
        }
        self.challengeClientData = challengeClientData
        
        try super.init(json: json)
        type = callbackType
        response = json
        
    }
    
    //  MARK: - Set values
    
    /// Sets `jws` value in callback response
    /// - Parameter jws: String value of `jws`]
    public func setAttestation(_ jws: String) {
        self.inputValues[self.token] = jws
    }
    
    
    /// Sets `deviceName` value in callback response
    /// - Parameter deviceName: String value of `deviceName`]
    public func setClientError(_ error: String) {
        self.inputValues[self.clientErrorKey] = error
    }
    
    public func setkeyId(_ keyId: String) {
        self.inputValues[self.keyId] = keyId
    }
    
    public func setVerification(_ appVerification: String) {
        self.inputValues[self.appVerification] = appVerification
    }
    
    public func setClientData(_ challenge: String) {
        self.inputValues[self.challengeClientData] = challenge
    }
    
    private func generate(completion: @escaping (String?, Bool) -> Void) {
        dcAppAttestService.generateKey(completionHandler: { keyId, error in

            guard let attestKeyId = keyId else {
                print("key generate failed: \(String(describing: error))")
                completion(nil, false)
                return
            }
            self.keyChainManager?.privateStore.set(attestKeyId, key: self.keyName)
            completion(attestKeyId, true)
            
        })
    }
    
    private func getAppAttestKey(completion: @escaping (String?, Bool) -> Void, forceGenerate: Bool = false) {
      
        if forceGenerate || keyChainManager?.privateStore.getString(keyName) == nil {
            generate(completion: completion)
            return
        }
        
      if let keyId = keyChainManager?.privateStore.getString(keyName) {
          completion(keyId, false)
      } else {
          completion(nil, false)
      }
    }
    
    // may be this challenge comes from server
    public func attest(completion: @escaping (_ result: AppIntegrityResult) -> Void, forceGenerate: Bool = false) {
        getAppAttestKey(completion: { keyId, foo in
            
            let hashValue = Data(SHA256.hash(data: self.challenge.data(using: .utf8)!))
            
            guard let keyId = keyId else {
                self.setClientError("invalid keyid")
                completion(.failure)
                return
            }
    
                self.dcAppAttestService.attestKey(keyId, clientDataHash: hashValue) { attestation, error in
                    guard error == nil else {
                        print(error?.localizedDescription ?? "")
                        if forceGenerate {
                            self.setClientError("key error")
                            completion(.failure)
                            return
                        }
                        self.attest(completion: completion, forceGenerate: true)
                        return
                    }
                    
                    guard let attestation = attestation?.base64EncodedString() else {
                        self.setClientError("base64 error")
                        completion(.failure)
                        return
                    }
                    
                    let appBundleIdentifier = Bundle.main.bundleIdentifier ?? "com.forgerock.ios.sdk"
                    let userClientData = ["challenge": self.challenge, "bundleId": appBundleIdentifier]
                    
                    let encoder = JSONEncoder()
                    guard let jsonData = try? encoder.encode(userClientData) else {
                        self.setClientError("jsonData error")
                        return
                    }
                    
                    
                    let clientDataHash = Data(SHA256.hash(data: jsonData))
                    DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
                        guard error == nil else {
                            self.setClientError("jsonData error")
                            print ("ERROR: Assertion not available right now")
                            return
                        }
                        
                        guard let assertion = assertion?.base64EncodedString() else {
                            self.setClientError("base64 error")
                            completion(.failure)
                            return
                        }
                        self.setVerification(assertion)
                        self.setAttestation(attestation)
//                        self.keyChainManager?.privateStore.set(attestation, key: self.appAttestToken)
                        self.setkeyId(keyId)
                        self.setClientData(jsonData.base64EncodedString())
                        completion(.success)
                    }
                    
                }
             
        }, forceGenerate: true)
    }
    

    public func validate(completion: @escaping (_ result: AppIntegrityResult) -> Void) {
        if DCDevice.current.isSupported {
            // A unique token will be generated for every call to this method
            DCDevice.current.generateToken(completionHandler: { token, error in
                guard let token = token else {
                    print("error generating token: \(error!)")
                    self.setClientError(error.debugDescription)
                    completion(.success)
                    return
                }
                self.setAttestation(token.base64EncodedString())
            })
        } else {
            self.setClientError("unsupported")
            completion(.failure)
        }
    }
    
    
}

public enum AppIntegrityResult {
    case success
    case failure
}

