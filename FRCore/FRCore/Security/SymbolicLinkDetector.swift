//
//  SymbolicLinkDetector.swift
//  FRCore
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// SymbolicLinkDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SymbolicLinkDetector: JailbreakDetector {
    
    /// Initializes SymbolicLinkDetector instance
    public init() { }
    
    /// Analyzes whether certain directories are symbolic links or not
    ///
    /// - NOTE: As part of Jailbreak process, it is commonly known that Jailbreak process will overwrite the partition, and changes some directories as symbolic link as original file/directory should remain as it was
    ///
    /// - Returns: returns 1.0 when certain directories are found as symbolic links; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        let urls: [String] = [
            "/var/lib/undecimus/apt", 
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]
        
        for urlString in urls {
            let url = URL(fileURLWithPath: urlString)
            if let ok = try? url.checkResourceIsReachable(), ok {
                let vals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
                if let vals = vals, let islink = vals.isSymbolicLink, islink {
                    Log.w("Security Warning: \(self) is returning 1.0")
                    return 1.0
                }
            }
        }
        return 0.0
    }
}
