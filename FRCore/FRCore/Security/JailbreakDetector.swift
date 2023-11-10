//
//  JailbreakDetector.swift
//  FRCore
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// JailbreakDetector protocol represents definition of JailbreakDetector which is used as individual analyzer to detect whether the device is Jailbroken or not. Each detector should analyze its logic to determine whether the device is suspicious to be Jailbroken or not, and returns the result score with maximum of 1.0
@objc
public protocol JailbreakDetector {
    
    /// Analyzes and returns the score of result
    ///
    /// - NOTE: analyze result **MUST** returns result in Double within range of 0.0 to 1.0; if the result value is less than 0.0 or greater than 1.0, the result will be forced to floor() or ceil()
    ///
    /// - Returns: returns result of analysis within range of 0.0 to 1.0
    @objc
    func analyze() -> Double
}

// MARK: -
extension JailbreakDetector {
    
    /// Validates whether given path can be opened through file system
    ///
    /// - Parameter path: designated path for a file or directory to check
    /// - Returns: returns true if given path can be opened; otherwise returns false
    func canOpen(path: String) -> Bool {
        let file = fopen(path, "r")
        guard file != nil else {
            return false
            
        }
        fclose(file)
        return true
    }
    
    func isSimulator() -> Bool {
        return checkCompile() || checkRuntime()
    }
    
    func checkRuntime() -> Bool {
        return ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] != nil
    }

    func checkCompile() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
