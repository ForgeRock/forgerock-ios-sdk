// 
//  CallbackTableViewCellFactory.swift
//  FRUI
//
//  Copyright (c) 2020-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import FRAuth


/**
 CallbackTableViewCellFactory is a representation of class responsible for managing UITableViewCell classes for corresponding Callback class in FRUI SDK's Authentication View Controller.
 CallbackTableViewCellFactory can be used to customize FRUI SDK's Authentication View Controller by implementing UITableViewCell and FRUICallbackTableViewCell protocol.
 
 ### Usage Example: ###
 ````
 CallbackTableViewCellFactory.shared.registerCallbackTableViewCell(callbackType: "NameCallback", cellClass: CustomNameCallbackCell.self, nibName: "CustomNameCallbackCell")
 ````
 Using `CallbackTableViewCellFactory`, FRUI Authentication View Controller renders UI with registered `FRUICallbackTableViewCel`l for speficied Callback type. Above example will render `CustomNameCallbackCell` for `NameCallback` in FRUI's Authentication View Controller.
 */
public class CallbackTableViewCellFactory: NSObject {
    
    //  MARK: - Property
    
    /// Shared instance of CallbackTableViewCellFactory
    public static let shared = CallbackTableViewCellFactory()
    /// An array of FRUICallbackTableViewCell classes mapped with Callback's type value as in String
    public var talbeViewCellForCallbacks: [String: FRUICallbackTableViewCell.Type] = [:]
    /// An array of Nib file names mapped with Callback's type value as in String
    public var tableViewCellNibForCallbacks: [String: String] = [:]
    
    
    //  MARK: - Init
    
    /// Initializes CallbackTableViewCellFactory instance with default values
    override init() {
        
        self.talbeViewCellForCallbacks = [
            "NameCallback": NameCallbackTableViewCell.self,
            "StringAttributeInputCallback": NameCallbackTableViewCell.self,
            "TextInputCallback": NameCallbackTableViewCell.self,
            "ValidatedCreateUsernameCallback": NameCallbackTableViewCell.self,
            "PasswordCallback": PasswordCallbackTableViewCell.self,
            "ValidatedCreatePasswordCallback": PasswordCallbackTableViewCell.self,
            "ChoiceCallback": ChoiceCallbackTableViewCell.self,
            "TermsAndConditionsCallback": TermsAndConditionsTableViewCell.self,
            "KbaCreateCallback": KbaCreateCallbackTableViewCell.self,
            "PollingWaitCallback": PollingWaitCallbackTableViewCell.self,
            "ConfirmationCallback": ConfirmationCallbackTableViewCell.self,
            "TextOutputCallback": TextOutputCallbackTableViewCell.self,
            "DeviceProfileCallback": DeviceAttributeTableViewCell.self,
            "BooleanAttributeInputCallback": BooleanAttributeInputCallbackTableViewCell.self,
            "NumberAttributeInputCallback": NameCallbackTableViewCell.self,
            "SuspendedTextOutputCallback": TextOutputCallbackTableViewCell.self,
            "WebAuthnAuthenticationCallback": WebAuthnCallbackTableViewCell.self,
            "WebAuthnRegistrationCallback": WebAuthnCallbackTableViewCell.self,
            "IdPCallback": IdPCallbackTableViewCell.self
        ]
        
        self.tableViewCellNibForCallbacks = [
            "NameCallback": "NameCallbackTableViewCell",
            "StringAttributeInputCallback": "NameCallbackTableViewCell",
            "TextInputCallback": "NameCallbackTableViewCell",
            "ValidatedCreateUsernameCallback": "NameCallbackTableViewCell",
            "PasswordCallback": "PasswordCallbackTableViewCell",
            "ValidatedCreatePasswordCallback": "PasswordCallbackTableViewCell",
            "ChoiceCallback": "ChoiceCallbackTableViewCell",
            "TermsAndConditionsCallback": "TermsAndConditionsTableViewCell",
            "KbaCreateCallback": "KbaCreateCallbackTableViewCell",
            "PollingWaitCallback": "PollingWaitCallbackTableViewCell",
            "ConfirmationCallback": "ConfirmationCallbackTableViewCell",
            "TextOutputCallback": "TextOutputCallbackTableViewCell",
            "DeviceProfileCallback": "DeviceAttributeTableViewCell",
            "BooleanAttributeInputCallback": "BooleanAttributeInputCallbackTableViewCell",
            "NumberAttributeInputCallback": "NameCallbackTableViewCell",
            "SuspendedTextOutputCallback": "TextOutputCallbackTableViewCell",
            "WebAuthnAuthenticationCallback": "WebAuthnCallbackTableViewCell",
            "WebAuthnRegistrationCallback": "WebAuthnCallbackTableViewCell",
            "IdPCallback": "IdPCallbackTableViewCell"
        ]
    }
    
    
    /// Registers new FRUICallbackTableViewCell class with Callback type value, and Nib file name; Nib file must be in same Bundle with FRUICallbackTableViewCell.
    /// - Parameter callbackType: String value of Callback class
    /// - Parameter cellClass: Custom UITableViewCell that understands and renders Callback, and implements FRUICallbackTableViewCell
    /// - Parameter nibName: Nib file name for the cellCalss
    public func registerCallbackTableViewCell(callbackType: String, cellClass: FRUICallbackTableViewCell.Type, nibName: String) {
        talbeViewCellForCallbacks[callbackType] = cellClass
        tableViewCellNibForCallbacks[callbackType] = nibName
    }
}
