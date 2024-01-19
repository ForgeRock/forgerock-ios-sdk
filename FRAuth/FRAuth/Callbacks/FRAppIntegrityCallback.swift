//
//  FRAppIntegrityCallback.swift
//  FRAuth
//
//  Copyright (c) 2023 - 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

public class FRAppIntegrityCallback: MultipleValuesCallback {
    
    /// The Challenge received from server in Output key
    public private(set) var challenge: String
    
    /// The attest token received from server in Output key
    public private(set) var attestToken: String
    
    /// Attestation token input key
    private var attestTokenKey: String
    
    /// Assertion token input key
    private var tokenKey: String
    
    /// Client Error input key
    private var clientErrorKey: String
    
    /// Key Identifier input key
    private var keyIdKey: String
    
    /// Client Data input key
    private var clientDataKey: String
    
    /// Payload to sign
    public private(set) var payload: String? = nil
    
    public private(set) var appIntegritykeys: FRAppIntegrityKeys = FRAppIntegrityKeys()
        
    //  MARK: - Init
    
    /// Designated initialization method for AppIntegrityCallback
    ///
    /// - Parameter json: JSON object of AppIntegrityCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
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
        
        guard let outputToken = outputDictionary[CBConstants.attest] as? String else {
            throw AuthError.invalidCallbackResponse("Missing Token")
        }
        
        self.attestToken = outputToken
    
        if !outputToken.isEmpty {
            FRLog.i("Persist the attestation reference")
            appIntegritykeys.updateKey(value: outputToken)
        }
        
        //parse inputs
        var inputNames = [String]()
        for input in inputs {
            guard let inputName = input[CBConstants.name] as? String else {
                throw AuthError.invalidCallbackResponse("Failed to parse input")
            }
            inputNames.append(inputName)
        }
        
        guard let attestKey = inputNames.filter({ $0.contains(CBConstants.attest) }).first else {
            throw AuthError.invalidCallbackResponse("Missing deviceIdKey")
        }
        self.attestTokenKey = attestKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        guard let keyId = inputNames.filter({ $0.contains(CBConstants.keyId) }).first else {
            throw AuthError.invalidCallbackResponse("Missing keyId")
        }
        self.keyIdKey = keyId
        
        guard let assertKey = inputNames.filter({ $0.contains(CBConstants.token) }).first else {
            throw AuthError.invalidCallbackResponse("Missing appVerification")
        }
        self.tokenKey = assertKey
        
        guard let clientData = inputNames.filter({ $0.contains(CBConstants.clientData) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientData")
        }
        self.clientDataKey = clientData
        
        try super.init(json: json)
        type = callbackType
        response = json
        
    }
    
    //  MARK: - Set values
    
    /// Sets `token` value in callback response
    /// - Parameter token: Base64 String value of attestation
    public func setAttestation(_ token: String) {
        self.inputValues[self.attestTokenKey] = token
    }
    
    /// Sets `error` value in callback response
    /// - Parameter error: String value of `error`
    public func setClientError(_ error: String) {
        self.inputValues[self.clientErrorKey] = error
    }
    
    /// Sets `keyId` value in callback response
    /// - Parameter keyId: Base64 String value of keyId
    public func setkeyId(_ keyId: String) {
        self.inputValues[self.keyIdKey] = keyId
    }
    
    /// Sets `token` value in callback response
    /// - Parameter token: Base64 String value of verification
    public func setAssertion(_ token: String) {
        self.inputValues[self.tokenKey] = token
    }
    
    /// Sets `clientData` value in callback response
    /// - Parameter clientData: Base64 String value of clientData
    public func setClientData(_ clientData: String) {
        self.inputValues[self.clientDataKey] = clientData
    }
    
    ///  Sets `payload` value to assert
    /// - Parameter payload: Assertion payload to sign
    public func setPayload(_ payload: String) {
        self.payload = payload
    }
    
    
    /// Attest the device for iOS14 and above devices
    /// - Throws: `FRDeviceCheckAPIFailure`
    @available(iOS 14.0, *)
    open func requestIntegrityToken() async throws {
        do {
            let result = try await FRAppAttestDomainModal.shared
                .requestIntegrityToken(challenge: challenge, payload: payload)
            self.setAttestation(result.appAttestKey)
            if let assertkey = result.assertKey {
                self.setAssertion(assertkey)
            }
            self.setkeyId(result.keyIdentifier)
            self.setClientData(result.clientDataHash)
            self.appIntegritykeys = result
        }
        catch {
            FRLog.e("Error: \(error.localizedDescription)")
            let failure: FRDeviceCheckAPIFailure = (error as? FRDeviceCheckAPIFailure) ?? .unknownError
            self.setClientError(failure.clientError)
            throw failure
        }
    }
    
    /// Attest the device
    /// - Parameter completionHandler: Returns FRAppIntegrityFailure for Error and nil if there are no errors
    open func requestIntegrityToken(completionHandler: @escaping (Error?) -> (Void)) {
        do {
            if #available(iOS 14.0, *) {
                Task {
                    do {
                        try await requestIntegrityToken()
                        completionHandler(nil)
                    }
                    catch {
                        completionHandler(error)
                    }
                }
            } else {
                let error = FRDeviceCheckAPIFailure.featureUnsupported
                FRLog.e("Error on supporting feature: \(error)")
                self.setClientError(error.clientError)
                completionHandler(error)
            }
        }
    }
    
    /// verify the attestation completed or not
    /// - Returns: true or false if the attestation key exist
    public func isAttestationCompleted() -> Bool {
        return appIntegritykeys.isAttestationCompleted()
    }
}
