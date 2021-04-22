//
//  SSHDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// SSHDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SSHDetector: JailbreakDetector {
    
    /// Initializes SSHDetector instance
    public init() { }
    
    /// Analyzes whether ssh or sshd is accessible or not
    ///
    /// - NOTE: ssh or sshd should not be accessible on non-Jailbroken devices
    ///
    /// - Returns: returns 1.0 if ssh or sshd is accessible; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let fileManager = FileManager.default
        let charArr: [Character] = ["/","u","s","r","/","b","i","n","/","s","s","h"]
        let searchPath = String(charArr)
        let charArr2: [Character] = ["/","u","s","r","/","s","b","i","n","/","s","s","h","d"]
        let searchPath2 = String(charArr2)
        
        if fileManager.fileExists(atPath: searchPath), fileManager.fileExists(atPath: searchPath2) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        if self.canOpen(path: searchPath), self.canOpen(path: searchPath2) {
            FRLog.w("Security Warning: \(self) is returning 1.0")
            return 1.0
        }
        
        return 0.0
    }
}
