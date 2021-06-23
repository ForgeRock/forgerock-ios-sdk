//
//  MultipleValuesCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 MultipleValuesCallback is a base Callback implementation that has one or more user input values. Any Callback that accepts multiple values from user interaction without OpenAM's validation with policies may inherit from this class.
 */
@objc(FRMultipleValuesCallback)
open class MultipleValuesCallback: Callback {
    
    //  MARK: - Property
    
    /// An array of inputName values
    @objc
    public var inputNames: [String]
    /// An array of input values
    @objc
    public var inputValues: [String: Any]
    /// String value of prompt attribute in Callback response; prompt is usually human readable text that can be displayed in UI
    @objc
    public var prompt: String?
    /// Unique identifier for this particular callback in Node
    public var _id: Int?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for MultipleValuesCallback
    ///
    /// ## Note ##
    /// Any Callback inherits from this class may override *init* method to define any additional instance property value.
    ///
    /// - Parameter json: JSON object of MultipleValuesCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        self.inputNames = []
        self.inputValues = [:]
        
        if let inputs = json[CBConstants.input] as? [[String: Any]] {
            for input in inputs {
                if let inputName = input[CBConstants.name] as? String {
                    self.inputNames.append(inputName)
                }
            }
        }
        
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.prompt, let prompt = output[CBConstants.value] as? String {
                    self.prompt = prompt
                }
            }
        }
        
        if let callbackId = json[CBConstants._id] as? Int {
            self._id = callbackId
        }
        
        try super.init(json: [:])
        self.type = callbackType
        self.response = json
    }
    
    
    //  MARK: - Build
    
    /// Builds JSON request payload for the Callback
    ///
    /// ## Note ##
    /// Any Callback inherits from this class may override *buildResponse()* method to construct the payload with any additional input value.
    ///
    /// - Returns: JSON request payload for the Callback
    open override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        
        var input: [[String: Any]] = []
        for (key, val) in self.inputValues {
            input.append([CBConstants.name: key, CBConstants.value: val])
        }
        responsePayload[CBConstants.input] = input
        return responsePayload
    }
}
