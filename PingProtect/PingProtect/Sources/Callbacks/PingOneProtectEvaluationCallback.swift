//
//  PingOneProtectEvaluationCallback.swift
//  PingProtect
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth


/**
 * Callback to evaluate Ping One Protect
 */
open class PingOneProtectEvaluationCallback: MultipleValuesCallback {
    
    /// The pauseBehavioralData received from server
    public private(set) var pauseBehavioralData: Bool?
    
    /// Signals input key in callback response
    private var signalsKey: String
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
    /// Designated initialization method for PingOneProtectEvaluationCallback
    ///
    /// - Parameter json: JSON object of PingOneProtectEvaluationCallback
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
        
        guard let pauseBehavioralData = outputDictionary[CBConstants.pauseBehavioralData] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing pauseBehavioralData")
        }
        self.pauseBehavioralData = pauseBehavioralData
        
        
        //parse inputs
        var inputNames = [String]()
        for input in inputs {
            guard let inputName = input[CBConstants.name] as? String else {
                throw AuthError.invalidCallbackResponse("Failed to parse input")
            }
            inputNames.append(inputName)
        }
        
        guard let signalsKey = inputNames.filter({ $0.contains(CBConstants.signals) }).first else {
            throw AuthError.invalidCallbackResponse("Missing signalsKey")
        }
        self.signalsKey = signalsKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        try super.init(json: json)
        type = callbackType
        response = json
    }
    
    
    /// Get Signals from the device
    /// - Parameter completion: Completion block for signals result
    open func getSignals(completion: @escaping ProtectResultCallback) {
        
        PIProtect.getData { data, error in
            if let data = data {
                self.setSignals(data)
                // Pause behavioral data collection if `pauseBehavioralData` is set to FALSE on the server node
                if let pauseBehavioralData = self.pauseBehavioralData, pauseBehavioralData == true {
                    PIProtect.pauseBehavioralData()
                }
                completion(.success)
            } else if let error = error {
                self.setClientError("Unable to get signals data")
                completion(.failure(error))
            }
        }
    }
    
    /// Sets `signals` value in callback response
    /// - Parameter signals: String value of `signals`]
    public func setSignals(_ signals: String) {
        self.inputValues[self.signalsKey] = signals
    }
    
    
    /// Sets `clientError` value in callback response
    /// - Parameter clientError: String value of `clientError`]
    public func setClientError(_ clientError: String) {
        self.inputValues[self.clientErrorKey] = clientError
    }
}


/// Definition for completion of Protect callback methods
public typealias ProtectResultCallback = (_ result: ProtectResult) -> Void


/// Result enum for Protect
public enum ProtectResult {
    case success
    case failure(Error)
}

