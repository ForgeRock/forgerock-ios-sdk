//
//  AptDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// AptDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class AptDetector: JailbreakDetector {
    
    /// Initializes AptDetector instance
    public init() { }
    
    /// Analyzes whether apt is accessible or not
    ///
    /// - Returns: returns 1.0 if apt is accessible; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let fileManager = FileManager.default
        let charArr: [Character] = ["/","e","t","c","/","a","p","t"]
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
