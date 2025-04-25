//
//  CustomCallback.swift
//  FRAuthTests
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRAuth

class CustomCallback: Callback {
    
    public var inputName: String?
    public var prompt: String?
    public var value: Any?
    public var customAttribute: String?
    public var _id: Int?
    
    public required init(json: [String : Any]) throws {
        
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
                else if let outputName = output["name"] as? String, outputName == "customAttribute", let customAttributeValue = output["value"] as? String {
                    self.customAttribute = customAttributeValue
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
    
    public override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        responsePayload["input"] = [["name": self.inputName!, "value": self.value!], ["name": "customAttribute", "value": self.customAttribute!]]
        responsePayload["custom"] = ["CustomCallbackInput": "CustomCallbackValue"]
        return responsePayload
    }
}
