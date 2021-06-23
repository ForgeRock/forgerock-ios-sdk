//
//  SymbolicLinkDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// SymbolicLinkDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SymbolicLinkDetector: JailbreakDetector {
    
    /// Initializes SymbolicLinkDetector instance
    public init() { }
    
    /// Analyzes whether "/Applications", "/Library/Ringtones", "/Library/Wallpaper" directory is a symbolic link or not
    ///
    /// - NOTE: As part of Jailbreak process, it is commonly known that Jailbreak process will overwrite the partition, and changes some directories as symbolic link as original file/directory should remain as it was. "/Applications", "/Library/Ringtones", and/or "/Library/Wallpaper" directory is one of them, and the class is checking whether "/Applications", "/Library/Ringtones", "/Library/Wallpaper" directory is found as symbolic link or not
    ///
    /// - Returns: returns 1.0 when "/Applications", "/Library/Ringtones", "/Library/Wallpaper" directory is found as a symbolic link; otherwise returns 0.0
    public func analyze() -> Double {
        FRLog.v("\(self) analyzing")
        let urls: [String] = ["/Applications", "/Library/Ringtones", "/Library/Wallpaper"]
        
        for urlString in urls {
            let url = URL(fileURLWithPath: urlString)
            if let ok = try? url.checkResourceIsReachable(), ok {
                let vals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
                if let vals = vals, let islink = vals.isSymbolicLink, islink {
                    FRLog.w("Security Warning: \(self) is returning 1.0")
                    return 1.0
                }
            }
        }
        return 0.0
    }
}
