//
//  ConfirmationCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
//to ask for YES/NO, OK/CANCEL, YES/NO/CANCEL or other similar confirmations

/**
 ConfirmationCallback is a representation of ConfirmationCallback in OpenAM to ask user for YES/NO, OK/CANCEL, YES/NO/CANCEL or other similar confirmations.
 */
@objc(FRConfirmationCallback)
public class ConfirmationCallback: Callback {
    
    //  MARK: - Property
    
    /// An array of string for available option(s)
    @objc
    public var options: [String]?
    /// Default option
    @objc
    public var defaultOption: Int = -1
    /// Confirmation Option enum; defaulted to .unknown when the value is not provided
    @objc
    public var option: Option
    /// Confirmation OptionType enum; defaulted to .unknown when the value is not provided
    @objc
    public var optionType: OptionType
    /// Confirmation MessageType enum; defaulted to .unknown when the value is not provided
    @objc
    public var messageType: MessageType
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
    
    /// Designated initialization method for ConfirmationCallback
    ///
    /// - Parameter json: JSON object of ConfirmationCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    @objc
    required init(json: [String: Any]) throws {
     
        self.option = .unknown
        self.optionType = .unknown
        self.messageType = .unknown
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let callbackId = json[CBConstants._id] as? Int {
            self._id = callbackId
        }
        
        if let inputs = json[CBConstants.input] as? [[String: Any]] {
            for input in inputs {
                if let inputName = input[CBConstants.name] as? String {
                    self.inputName = inputName
                }
                if let inputValue = input[CBConstants.value] {
                    self.value = inputValue
                }
            }
        }
        else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.prompt, let prompt = output[CBConstants.value] as? String {
                    self.prompt = prompt
                }
                else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.messageType, let messageTypeInt = output[CBConstants.value] as? Int, let messageType = MessageType(rawValue: messageTypeInt) {
                    self.messageType = messageType
                }
                else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.option, let optionInt = output[CBConstants.value] as? Int, let option = Option(rawValue: optionInt) {
                    self.option = option
                }
                else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.optionType, let optionTypeInt = output[CBConstants.value] as? Int, let optionType = OptionType(rawValue: optionTypeInt) {
                    self.optionType = optionType
                }
                else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.options, let options = output[CBConstants.value] as? [String] {
                    self.options = options
                }
                else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.defaultOption, let defaultOption = output[CBConstants.value] as? Int {
                    self.defaultOption = defaultOption
                }
            }
        }
        else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
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
    /// - Returns: JSON request payload for the Callback
    public override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        responsePayload[CBConstants.input] = [[CBConstants.name: self.inputName, CBConstants.value: self.value]]
        return responsePayload
    }
}
