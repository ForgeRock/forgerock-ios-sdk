//
//  DyldDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
#if SWIFT_PACKAGE
import cFRAuth
#endif

/// DyldDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class DyldDetector: JailbreakDetector {
    
    /// Initializes DyldDetector instance
    public init() { }
    
    /// Analyzes whether dynamically loaded libraries contain any one of commonly known libraries from Jailbreak process
    ///
    /// - NOTE: MobileSubstrate is commonly used library in Jailbroken device, and by loading all dynamic library, and checking whether the library was loaded or not is used in this validation.
    ///
    /// - Returns: return 1.0 if MobileSubstrate library was loaded; ohterwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let result = validate_dyld()
        if result {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        return 0.0
    }
}
