//
//  BashDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// BashDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class BashDetector: JailbreakDetector {
    
    /// Initializes BashDetector instance
    public init() { }
    
    /// Analyzes whether bash is accessible or not
    ///
    /// - NOTE: bash should not be accessible on non-Jailbroken device
    ///
    /// - Returns: return 1.0 if bash is accessible; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let fileManager = FileManager.default
        let charArr: [Character] = ["/","b","i","n","/","b","a","s","h"]
        let searchPath = String(charArr)
        
        if fileManager.fileExists(atPath: searchPath) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        if self.canOpen(path: searchPath) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        return 0.0
    }
}
