//
//  TermsAndConditionsCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 TermsAndConditionsCallback is a callback to collect a user's acceptance of the configured Terms &amp; Conditions.
 */
@objc(FRTermsAndConditionsCallback)
public class TermsAndConditionsCallback: SingleValueCallback {
    
    //  MARK: - Property
    
    /// Created date of given Terms &amp; Conditions in string
    @objc
    public var createDate: String?
    /// String value of Terms &amp; Conditions
    @objc
    public var terms: String?
    /// Specified version of given Terms &amp; Conditions
    @objc
    public var version: String?
    
    
    //  MARK: - Init
    
    /// Designated initialization method for TermsAndConditionsCallback
    ///
    /// - Parameter json: JSON object of TermsAndConditionsCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        try super.init(json: json)
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let name = output[CBConstants.name] as? String, name == CBConstants.version, let version = output[CBConstants.value] as? String {
                self.version = version
            } else if let name = output[CBConstants.name] as? String, name == CBConstants.createDate, let createDate = output[CBConstants.value] as? String {
                self.createDate = createDate
            } else if let name = output[CBConstants.name] as? String, name == CBConstants.terms, let terms = output[CBConstants.value] as? String {
                self.terms = terms
            }
        }
        
        guard self.terms == self.terms else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
    }
    
    
    /// Sets Boolean input value for TermsAndConditionsCallback.
    /// - Parameter val: Boolean input value for Callback
    public func setValue(_ val: Bool) {
        self._value = val
    }
}
