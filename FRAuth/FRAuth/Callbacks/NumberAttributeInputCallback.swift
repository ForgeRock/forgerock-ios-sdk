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
    
    var doubleValue: Double?
    @objc public override var value: Any? {
        set {
            if let newValue = newValue as? Double {
                doubleValue = newValue
            }
            else if let newValue = newValue as? String, let newDoubleValue = Double(newValue){
                doubleValue = newDoubleValue
            }
            else {
                FRLog.e("Unexpected data type is set for NumberAttributeInputCallback: \(String(describing: newValue))")
            }
        }
        get {
            return doubleValue
        }
    }
}
