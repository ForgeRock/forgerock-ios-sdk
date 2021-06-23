//
//  FRChoiceCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

/**
 ChoiceCallback is a representation of OpenAM's ChoiceCallback to collect single user input from available choices, and with predefined default choice, and to retrieve selected choice from user interaction.
 */
@objc(FRChoiceCallback)
public class ChoiceCallback: SingleValueCallback {
    
    //  MARK: - Properties
    
    /// List of available options for ChoiceCallback
    @objc
    public var choices:[String] = []
    /// Default choice value defined from OpenAM
    @objc
    public var defaultChoice:Int
    

    //  MARK: - Init method
    
    /// Designated initialization method for ChoiceCallback
    ///
    /// - Parameter json: JSON object of ChoiceCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        self.choices = []
        self.defaultChoice = 0
        
        try super.init(json: json)
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let name = output[CBConstants.name] as? String, name == CBConstants.choices, let choices = output[CBConstants.value] as? [String] {
                self.choices = choices
            } else if let name = output[CBConstants.name] as? String, name == CBConstants.defaultChoice, let defaultChoice = output[CBConstants.value] as? Int {
                self.defaultChoice = defaultChoice
            }
        }
        
        guard let _ = self.prompt, let _ = self.inputName, self.choices.count > 0 else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        self._value = "\(self.defaultChoice)"
    }
    
    
    /// Sets Int input value of the choice for ChoiceCallback.
    /// - Parameter val: Int input value for ChoiceCallback
    public func setValue(_ val: Int) {
        self._value = val
    }
}
