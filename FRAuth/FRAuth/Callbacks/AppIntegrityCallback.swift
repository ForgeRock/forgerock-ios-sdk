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
    
    let appIntegrityDomainModal = AppIntegrityDomainModal()
    
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
        
        guard let deviceIdKey = inputNames.filter({ $0.contains("IDToken1token") }).first else {
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
    
    open func attest() async throws {
        do {
     
            let keyIdentifier = try await appIntegrityDomainModal.generateKey()
            let attest = try await appIntegrityDomainModal.attest(challenge: challenge, keyIdentifier: keyIdentifier)
            let assert = try await appIntegrityDomainModal.assert(challenge: challenge, keyIdentifier: keyIdentifier)
        
            self.setAttestation(attest)
            self.setVerification(assert.0)
            self.setkeyId(keyIdentifier)
            self.setClientData(assert.1)
            
            
        }
        catch {
            FRLog.e(error.localizedDescription)
            self.setClientError(error.localizedDescription)
            throw error
        }
    }
        
}
