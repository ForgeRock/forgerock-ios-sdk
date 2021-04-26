// 
//  HiddenValueCallback.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

public class HiddenValueCallback: SingleValueCallback {

    @objc public var id: String?
    
    public var isWebAuthnOutcome: Bool = false
    
    //  MARK: - Init
    
    /// Designated initialization method for HiddenValueCallback
    ///
    /// - Parameter json: JSON object of HiddenValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        try super.init(json: json)
        
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.id, let idValue = output[CBConstants.value] as? String {
                    self.id = idValue
                }
            }
        }
        
        if self.id == CBConstants.webAuthnOutcome {
            self.isWebAuthnOutcome = true
        }
    }
}
