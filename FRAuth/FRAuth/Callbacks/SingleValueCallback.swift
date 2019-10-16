//
//  SingleStringValueCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 SingleValueCallback is a base Callback implementation that has single user input value. Any Callback that accepts single value from user interaction without OpenAM's validation with policies may inherit from this class.
 */
@objc(FRSingleValueCallback)
public class SingleValueCallback: Callback {
    
    //  MARK: - Property
    
    /// String value of inputName attribute in Callback response
    @objc
    public var inputName: String?
    /// String value of prompt attribute in Callback response; prompt is usually human readable text that can be displayed in UI
    @objc
    public var prompt: String?
    /// A value provided from user interaction for this particular callback; the value can be any type
    @objc
    public var value: Any?
    /// Unique identifier for this particular callback in Node
    public var _id: Int?
    
    //  MARK: - Init
    
    /// Designated initialization method for SingleValueCallback
    ///
    /// ## Note ##
    /// Any Callback inherits from this class may override *init* method to define any additional instance property value.
    ///
    /// - Parameter json: JSON object of SingleValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        guard let callbackType = json["type"] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let inputs = json["input"] as? [[String: Any]] {
            for input in inputs {
                if let inputName = input["name"] as? String {
                    self.inputName = inputName
                }
                if let inputValue = input["value"] as? String {
                    self.value = inputValue
                }
            }
        }
        
        if let outputs = json["output"] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output["name"] as? String, outputName == "prompt", let prompt = output["value"] as? String {
                    self.prompt = prompt
                }
            }
        }
        
        if let callbackId = json["_id"] as? Int {
            self._id = callbackId
        }
        
        guard let _ = self.inputName  else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
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
    public override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        responsePayload["input"] = [["name": self.inputName, "value": self.value]]
        return responsePayload
    }
}
