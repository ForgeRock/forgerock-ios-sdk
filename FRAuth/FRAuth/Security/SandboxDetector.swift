//
//  SandboxDetector.swift
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

/// SandboxDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SandboxDetector: JailbreakDetector {
    
    /// Initializes SandboxDetector instance
    public init() { }
    
    /// Analyzes whether the device has an access to special system method on non-jailbroken devices
    ///
    /// - Returns: returns 1.0 when the device can successfully use fork() and return pid; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let result = validate_sandbox()
        if result {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        return 0.0
    }
}
