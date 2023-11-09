//
//  DyldDetector.swift
//  FRCore
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import MachO

/// DyldDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class DyldDetector: JailbreakDetector {
    
    /// Initializes DyldDetector instance
    public init() { }
    
    /// Analyzes whether dynamically loaded libraries contain any one of commonly known libraries from Jailbreak process
    ///
    /// - Returns: return 1.0 if any one of commonly known libraries from Jailbreak process  was loaded; ohterwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        
        let suspiciousLibraries: Set<String> = [
            "SubstrateLoader.dylib",
            "SSLKillSwitch2.dylib",
            "SSLKillSwitch.dylib",
            "MobileSubstrate.dylib",
            "TweakInject.dylib",
            "CydiaSubstrate",
            "cynject",
            "CustomWidgetIcons",
            "PreferenceLoader",
            "RocketBootstrap",
            "WeeLoader",
            "/.file", // HideJB (2.1.1) changes full paths of the suspicious libraries to "/.file"
            "libhooker",
            "SubstrateInserter",
            "SubstrateBootstrap",
            "ABypass",
            "FlyJB",
            "Substitute",
            "Cephei",
            "Electra",
            "AppSyncUnified-FrontBoard.dylib",
            "Shadow",
            "FridaGadget",
            "frida",
            "libcycript"
        ]
        for libraryIndex in 0..<_dyld_image_count() {
            
            // _dyld_get_image_name returns const char * that needs to be casted to Swift String
            guard let loadedLibrary = String(validatingUTF8: _dyld_get_image_name(libraryIndex)) else { continue }
            
            for suspiciousLibrary in suspiciousLibraries {
                if loadedLibrary.lowercased().contains(suspiciousLibrary.lowercased()) {
                    Log.w("Security Warning: \(self) is returning 1.0")
                    return 1.0
                }
            }
        }
        
        return 0.0
    }
}
