// 
//  AbstractProtectCallback.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 * Parent Callback used by Ping One Protect callbacks
 */
open class ProtectCallback: MultipleValuesCallback, NodeAware {
    
    
    //  MARK: - Property
    
    /// An array of inputName values
    public var outputNames: [String]
    /// An array of input values
    public var outputValues: [String: Any]
    /// Client Error input key in callback response
    public var clientErrorKey: String = String()
    /// Indicates if the callback is derived from a MetadataCallback
    public var derivedCallback: Bool
    /// The Node that associate with the Callback
    public internal(set) var node: Node?
    
    
    /// Designated initialization method for Ping Protect callbacks
    ///
    /// - Parameter json: JSON object of the callback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        guard json[CBConstants.type] is String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        // Check if it's a derived callback
        self.derivedCallback = ProtectCallback.isDerivedCallback(json)
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        // parse outputs
        var outputNames = [String]()
        var outputValues = [String: Any]()
        for output in outputs {
            guard let outputName = output[CBConstants.name] as? String, let outputValue = output[CBConstants.value] else {
                throw AuthError.invalidCallbackResponse("Failed to parse output")
            }
            if derivedCallback && outputName == CBConstants.data {
                for (key, value) in outputValue as! [String: Any] {
                    outputNames.append(key)
                    outputValues[key] = value
                }
            } else {
                outputNames.append(outputName)
                outputValues[outputName] = outputValue
            }
        }
        self.outputNames = outputNames
        self.outputValues = outputValues

        try super.init(json: json)
        
        if !self.derivedCallback {
            guard let clientErrorKey = self.inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
                throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
            }
            self.clientErrorKey = clientErrorKey
        }
    }
    
    
    /// Sets `clientError` value in callback response
    /// - Parameter clientError: String value of `clientError`]
    public func setClientError(_ clientError: String) {
        if derivedCallback {
            self.setClientErrorInHiddenCallback(value: clientError)
        } else {
            self.inputValues[self.clientErrorKey] = clientError
        }
    }
    
    /// Sets `clientError` value  to the `HiddenValueCallback` which is associated with the ProtectCallback
    /// - Parameter clientError: String value of `clientError`]
    func setClientErrorInHiddenCallback(value: String) {
        if let node = node {
            for callback in node.callbacks {
                if let hiddenCallback = callback as? HiddenValueCallback {
                    if let callbackId = hiddenCallback.id, callbackId.contains(CBConstants.clientError) {
                        hiddenCallback.setValue(value)
                        return
                    }
                }
            }
        }
        FRLog.e("Failed to set client error to HiddenValueCallback; HiddenValueCallback with 'clientError' is missing")
    }
    
    /// Check the type of Protect callback for the given MetadataCallback
    /// - Parameter json: raw JSON payload for MetdataCallback
    /// - Returns: ProtectCallbackType enum
    static func getProtectDerivedCallbackType(_ json: [String: Any]) -> ProtectCallbackType {
        if let callbackType = json[CBConstants.type] as? String, callbackType == CallbackType.MetadataCallback.rawValue {

            if let outputs = json[CBConstants.output] as? [[String: Any]] {
                for output in outputs {
                    //  If output attribute contains `data` attribute, and within `data` attribute, if it contains `_type = PingOneProtect`, then it is used for Protect
                    if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.data, let outputValue = output[CBConstants.value] as? [String: Any], let outputType = outputValue[CBConstants._type] as? String, outputType == CBConstants.pingOneProtect {
                        
                        if let outputAction = outputValue[CBConstants._action] as? String {
                            if outputAction == CBConstants.protectInitialize {
                                return .initialize
                            } else if outputAction == CBConstants.protectRiskEvaluation {
                                return .riskEvaluation
                            } else {
                                return .invalid
                            }
                        }
                    }
                }
            }
        }
        
        return .invalid
    }
    
    
    /// Check if the given MetadataCallback is a derived callback
    /// - Parameter json: raw JSON payload for MetdataCallback
    /// - Returns: true if this is a derived callback, otherwise false
    public static func isDerivedCallback(_ json: [String: Any]) -> Bool {
        var derivedCallback = false
        let protectCallbackType = ProtectCallback.getProtectDerivedCallbackType(json)
        if protectCallbackType.rawValue == ProtectCallbackType.initialize.rawValue || protectCallbackType.rawValue == ProtectCallbackType.riskEvaluation.rawValue {
            derivedCallback = true
        }
        return derivedCallback
    }
    
    
    func setNode(node: Node?) {
        self.node = node
    }
}


/// Protect Callback type enumeration
enum ProtectCallbackType: String {
    /// registration
    case initialize = "PingOneProtectInitializeCallback"
    /// authentication
    case riskEvaluation = "PingOneProtectEvaluationCallback"
    /// invalid Protect Callback type
    case invalid = ""
}
