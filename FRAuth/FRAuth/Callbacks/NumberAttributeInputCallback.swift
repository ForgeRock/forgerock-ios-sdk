// 
//  NumberAttributeInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 NumberAttributeInputCallback is a representation of OpenAM's NumberAttributeInputCallback to collect double value with OpenAM validation and given policies.
 */
@objc(FRNumberAttributeInputCallback)
public class NumberAttributeInputCallback: AttributeInputCallback {    
    
    /// Sets Double input value for NumberAttributeInputCallback.
    /// - Parameter val: Double input value for Callback
    @objc(setNumberValue:)
    public func setValue(_ val: Double) {
        self._value = val
    }
}
