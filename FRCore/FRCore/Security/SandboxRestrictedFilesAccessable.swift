// 
//  SandboxRestrictedFilesAccessable.swift
//  FRCore
//
//  Copyright (c) 2025 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// SandboxRestrictedFilesAccessable is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SandboxRestrictedFilesAccessable: JailbreakDetector {
    
    /// Initializes SandboxRestrictedFilesAccessable instance
    public init() { }
    
    /// Analyzes whether the app has access the restricted directories
    ///
    /// - Returns: returns 1.0 if the app has access to restricted directories; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        
        let restrictedPaths = ["/var/root/", "/var/mobile/Library/Preferences"]
        for path in restrictedPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                Log.w("Security Warning: \(self) is returning 1.0")
                return 1.0
            }
        }
        
        return 0.0
    }
}
