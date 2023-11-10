//
//  CydiaDetector.swift
//  FRCore
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// CydiaDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
@available(*, deprecated, message: "Use SuspiciousFilesExistenceDetector and SuspiciousFilesAccessibleDetector instead")
public class CydiaDetector: JailbreakDetector {
    
    /// Initializes CydiaDetector instance
    public init() { }
    
    /// Analyzes whether Cydia.app exists, and is accessible or not
    ///
    /// - Returns: returns 1.0 if Cydia.app is found or accessible; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        let fileManager = FileManager.default
        let charArr: [Character] = ["/","A","p","p","l","i","c","a","t","i","o","n","s","/","C","y","d","i","a",".","a","p","p"]
        let searchPath = String(charArr)
        // Validate if Cydia app exists
        if fileManager.fileExists(atPath: searchPath) {
            Log.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        // Validate if Cydia app can be opened
        if self.canOpen(path: searchPath) {
            Log.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        return 0.0
    }
}
