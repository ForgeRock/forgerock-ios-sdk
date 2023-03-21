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

open class AppIntegrityCallback: MultipleValuesCallback {
    

    public private(set) var challenge: String
    /// The authentication type of the journey
    
    
    /// Device id input key in callback response
    private var token: String
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
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
        
        guard let deviceIdKey = inputNames.filter({ $0.contains("IDToken1tokenId") }).first else {
            throw AuthError.invalidCallbackResponse("Missing deviceIdKey")
        }
        self.token = deviceIdKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains("IDToken1clientError") }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        try super.init(json: json)
        type = callbackType
        response = json
        
    }
    
    //  MARK: - Set values
    
    /// Sets `jws` value in callback response
    /// - Parameter jws: String value of `jws`]
    public func settoken(_ jws: String) {
        self.inputValues[self.token] = jws
    }
    
    
    /// Sets `deviceName` value in callback response
    /// - Parameter deviceName: String value of `deviceName`]
    public func setClientError(_ error: String) {
        self.inputValues[self.clientErrorKey] = error
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
                self.settoken(token.base64EncodedString())
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
