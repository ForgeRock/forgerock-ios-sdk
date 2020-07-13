//
//  StringAttributeInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 StringAttributeInputCallback is a representation of OpenAM's StringAttributeInputCallback to collect single value of string user attribute with OpenAM validation with given policies.
 */
@objc(FRStringAttributeInputCallback)
public class StringAttributeInputCallback: AttributeInputCallback {
    
    /// Sets String input value for StringAttributeInputCallback.
    /// - Parameter val: String input value for Callback
    @objc(setStringValue:)
    public func setValue(_ val: String) {
        self._value = val
    }
}
