//
//  SingleStringValueCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 SingleValueCallback is a base Callback implementation that has single user input value. Any Callback that accepts single value from user interaction without OpenAM's validation with policies may inherit from this class.
 */
@objc(FRSingleValueCallback)
open class SingleValueCallback: Callback {
    
    //  MARK: - Property
    
    /// String value of inputName attribute in Callback response
    @objc public var inputName: String?
    /// String value of prompt attribute in Callback response; prompt is usually human readable text that can be displayed in UI
    @objc public var prompt: String?
    /// Unique identifier for this particular callback in Node
    public var _id: Int?
    
    /// A value provided from user interaction for this particular callback; the value can be any type
    var _value: Any?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for SingleValueCallback
    ///
    /// ## Note ##
    /// Any Callback inherits from this class may override *init* method to define any additional instance property value.
    ///
    /// - Parameter json: JSON object of SingleValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let inputs = json[CBConstants.input] as? [[String: Any]] {
            for input in inputs {
                if let inputName = input[CBConstants.name] as? String {
                    if inputName.range(of: "IDToken\\d{1,2}$", options: .regularExpression, range: nil, locale: nil) != nil {
                        self.inputName = inputName
                        if let inputValue = input[CBConstants.value] as? String {
                            self._value = inputValue
                        }
                    }
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
        
        guard let _ = self.inputName  else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        try super.init(json: [:])
        self.type = callbackType
        self.response = json
    }
    
    
    //  MARK: - Value
    
    /// Sets input value in Callback with generic type
    /// - Parameter val: value to be set for Callback's input
    @objc(setInputValue:)
    public func setValue(_ val: Any?) {
        self._value = val
    }
    
    
    /// Returns input value in Callback with generic type
    /// - Returns: value that was set for Callback's input
    @objc(getInputValue)
    public func getValue() -> Any? {
        return self._value
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
        for (key, value) in responsePayload {
            if key == CBConstants.input, var inputs = value as? [[String: Any]] {
                for (index, input) in inputs.enumerated() {
                    if let inputName = input[CBConstants.name] as? String, inputName == self.inputName {
                        inputs[index][CBConstants.value] = self._value
                    }
                }
                responsePayload[CBConstants.input] = inputs
            }
        }
        return responsePayload
    }
}
