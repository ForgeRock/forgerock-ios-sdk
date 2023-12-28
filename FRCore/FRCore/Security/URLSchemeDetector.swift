//
//  URLSchemeDetector.swift
//  FRCore
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit

/// URLSchemeDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class URLSchemeDetector: JailbreakDetector {
    
    /// Initializes URLSchemeDetector instance
    public init() { }
    
    /// Analyzes whether certain url schemes can be opened.
    ///
    /// - Returns: returns 1.0 if any of the listed url schemes can be opened; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        
        // "cydia://" is not in the list as there is app in the official App Store
        // that has the cydia:// URL scheme registered, so it may cause false positive
        let urlSchemes = [
            "undecimus://",
            "sileo://",
            "zbra://",
            "filza://",
            "activator://"
        ]
        for urlScheme in urlSchemes {
            if let url = URL(string: urlScheme) {
                if UIApplication.shared.canOpenURL(url) {
                    Log.w("Security Warning: \(self) is returning 1.0")
                    return 1.0
                }
            }
        }
        
        return 0.0
    }
}

