// 
//  BooleanAttributeInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


/**
 BooleanAttributeInputCallback is a representation of OpenAM's BooleanAttributeInputCallback to collect single boolean value with OpenAM validation and given policies.
 */
@objc(FRBooleanAttributeInputCallback)
public class BooleanAttributeInputCallback: AttributeInputCallback {
    
    var booleanValue: Bool?
    @objc public override var value: Any? {
        set {
            if let newValue = newValue as? Bool {
                booleanValue = newValue
            }
            else {
                FRLog.e("Unexpected data type is set for BooleanAttributeInputCallback: \(String(describing: newValue))")
            }
        }
        get {
            return booleanValue
        }
    }
}
