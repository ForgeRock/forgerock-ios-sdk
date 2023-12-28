//
//  SuspiciousObjCClassesDetector.swift
//  FRCore
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// SuspiciousObjCClassesDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SuspiciousObjCClassesDetector: JailbreakDetector {
    
    /// Initializes SuspiciousObjCClassesDetector instance
    public init() { }
    
    /// Analyzes whether suspicious Obj C classes are found
    ///
    /// - Returns: returns 1.0 if suspicious Obj C classes are found, otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        
        if let shadowRulesetClass = objc_getClass("ShadowRuleset") as? NSObject.Type {
            let selector = Selector(("internalDictionary"))
            if class_getInstanceMethod(shadowRulesetClass, selector) != nil {
                Log.w("Security Warning: \(self) is returning 1.0")
                return 1.0
            }
        }
        
        return 0.0
    }
}
