//
//  PrivateFileWritableDetector.swift
//  FRCore
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// PrivateFileWritableDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
@available(*, deprecated, message: "Use RestrictedDirectoriesWritableDetector instead")
public class PrivateFileWritableDetector: JailbreakDetector {
    
    /// Initializes PrivateFileWritableDetector instance
    public init() { }
    
    /// Analyzes whether the app can write to a private directory
    ///
    /// - NOTE: /private directory is a private access that should only be accessed through iOS system, and the app should not have an access to the location to write/read
    ///
    /// - Returns: returns 1.0 if the app has write access to /private directory; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        
        let fileManager = FileManager.default
        var isFileWritable = false
        let path = "/private/" + UUID().uuidString
        
        // Try to generate a file with Random UUID as name
        // Make sure to handle writing / deleting operation separately to correctly measure the result
        do {
            try "[FRCore] PRivateFileWritableDetection Test".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            isFileWritable = true
        } catch {
            isFileWritable = false
        }
        
        // Make sure if the file was written, delete the file
        if isFileWritable {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                // Warn that file is created, but was able to delete
            }
        }
        
        if isFileWritable {
            Log.w("Security Warning: \(self) is returning 1.0")
        }
        
        return isFileWritable ? 1.0 : 0.0
    }
}
