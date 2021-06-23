//
//  AttributeInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 Base implementation of a Callback for collection of a single identity object attribute from a user.
 */
@objc(FRAttributeInputCallback)
public class AttributeInputCallback: AbstractValidatedCallback {
    
    //  MARK: - Property
    
    /// Name of given attribute
    @objc
    public var name: String?
    /// Boolean indicator whether given attribute is required or not
    @objc
    public var required: Bool = false
    
    
    //  MARK: - Init method
    
    /// Designated initialization method for AttributeInputCallback
    ///
    /// - Parameter json: JSON object of AttributeInputCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        try super.init(json: json)
        
        guard let outputs = json["output"] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let name = output[CBConstants.name] as? String, name == CBConstants.prompt, let prompt = output[CBConstants.value] as? String {
                self.prompt = prompt
            } else if let name = output[CBConstants.name] as? String, name == CBConstants.name, let nameValue = output[CBConstants.value] as? String {
                self.name = nameValue
            } else if let name = output[CBConstants.name] as? String, name == CBConstants.required, let required = output[CBConstants.value] as? Bool {
                self.required = required
            }
        }
    }
}
