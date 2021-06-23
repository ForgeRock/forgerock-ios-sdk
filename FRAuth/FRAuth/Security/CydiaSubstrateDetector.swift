//
//  CydiaSubstrateDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// CydiaSubstrateDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class CydiaSubstrateDetector: JailbreakDetector {
    
    /// Initializes CydiaSubstrateDetector instance
    public init() { }
    
    /// Analyzes whether MobileSubstrate is found or accessible or not
    ///
    /// - NOTE: MobileSubstrate (or Cydia Substrate) is known as the de fecto framework that allows 3rd-party developers to provide run-time patches through MobileSubstrate to system
    ///
    /// - Returns: returns 1.0 if MobileSubstrate is found or accessible; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let fileManager = FileManager.default
        let charArr: [Character] = ["/","L","i","b","r","a","r","y","/","M","o","b","i","l","e","S","u","b","s","t","r","a","t","e","/","M","o","b","i","l","e","S","u","b","s","t","r","a","t","e",".","d","y","l","i","b"]
        let searchPath = String(charArr)
        
        // Validate if Cydia app exists
        if fileManager.fileExists(atPath: searchPath) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        // Validate if Cydia app can be opened
        if self.canOpen(path: searchPath) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        return 0.0
    }
}
