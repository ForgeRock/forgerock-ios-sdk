// 
//  BooleanAttributeInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 BooleanAttributeInputCallback is a representation of OpenAM's BooleanAttributeInputCallback to collect single boolean value with OpenAM validation and given policies.
 */
@objc(FRBooleanAttributeInputCallback)
public class BooleanAttributeInputCallback: AttributeInputCallback {
    
    /// Sets Boolean input value for BooleanAttributeInputCallback.
    /// - Parameter val: Boolean input value for Callback
    @objc(setBoolValue:)
    public func setValue(_ val: Bool) {
        self._value = val
    }
}
