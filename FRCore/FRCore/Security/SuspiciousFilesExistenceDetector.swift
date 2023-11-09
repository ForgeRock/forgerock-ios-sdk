//
//  SuspiciousFilesExistenceDetector.swift
//  FRCore
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// SuspiciousFilesExistenceDetector is a JailbreakDetector class, and is used as one of default JailbreakDetector's detectors to determine whether the device is Jailbroken or not
public class SuspiciousFilesExistenceDetector: JailbreakDetector {
    
    /// Initializes SuspiciousFilesExistenceDetector instance
    public init() { }
    
    /// Analyzes whether suspicious files exist
    ///
    /// - Returns: returns 1.0 if suspicious files are found; otherwise returns 0.0
    public func analyze() -> Double {
        Log.v("\(self) analyzing")
        let fileManager = FileManager.default
        var paths = [
            "/var/mobile/Library/Preferences/ABPattern", // A-Bypass
            "/usr/lib/ABDYLD.dylib", // A-Bypass,
            "/usr/lib/ABSubLoader.dylib", // A-Bypass
            "/usr/sbin/frida-server", // frida
            "/etc/apt/sources.list.d/electra.list", // electra
            "/etc/apt/sources.list.d/sileo.sources", // electra
            "/.bootstrapped_electra", // electra
            "/usr/lib/libjailbreak.dylib", // electra
            "/jb/lzma", // electra
            "/.cydia_no_stash", // unc0ver
            "/.installed_unc0ver", // unc0ver
            "/jb/offsets.plist", // unc0ver
            "/usr/share/jailbreak/injectme.plist", // unc0ver
            "/etc/apt/undecimus/undecimus.list", // unc0ver
            "/var/lib/dpkg/info/mobilesubstrate.md5sums", // unc0ver
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/jb/jailbreakd.plist", // unc0ver
            "/jb/amfid_payload.dylib", // unc0ver
            "/jb/libjailbreak.dylib", // unc0ver
            "/usr/libexec/cydia/firmware.sh",
            "/var/lib/cydia",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/Users/",
            "/var/log/apt",
            "/Applications/Cydia.app",
            "/private/var/stash",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/cache/apt/",
            "/private/var/log/syslog",
            "/private/var/tmp/cydia.log",
            "/Applications/Icy.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/blackra1n.app",
            "/Applications/SBSettings.app",
            "/Applications/FakeCarrier.app",
            "/Applications/WinterBoard.app",
            "/Applications/IntelliScreen.app",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/CydiaSubstrate.dylib",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/Applications/Sileo.app",
            "/var/binpack",
            "/Library/PreferenceBundles/LibertyPref.bundle",
            "/Library/PreferenceBundles/ShadowPreferences.bundle",
            "/Library/PreferenceBundles/ABypassPrefs.bundle",
            "/Library/PreferenceBundles/FlyJBPrefs.bundle",
            "/Library/PreferenceBundles/Cephei.bundle",
            "/Library/PreferenceBundles/SubstitutePrefs.bundle",
            "/Library/PreferenceBundles/libhbangprefs.bundle",
            "/usr/lib/libhooker.dylib",
            "/usr/lib/libsubstitute.dylib",
            "/usr/lib/substrate",
            "/usr/lib/TweakInject",
            "/var/binpack/Applications/loader.app", // checkra1n
            "/Applications/FlyJB.app", // Fly JB X
            "/Applications/Zebra.app", // Zebra
            "/Library/BawAppie/ABypass", // ABypass
            "/Library/MobileSubstrate/DynamicLibraries/SSLKillSwitch2.plist", // SSL Killswitch
            "/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.plist", // PreferenceLoader
            "/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.dylib", // PreferenceLoader
            "/Library/MobileSubstrate/DynamicLibraries", // DynamicLibraries directory in general
            "/var/mobile/Library/Preferences/me.jjolano.shadow.plist",
            "/Applications/Snoop-itConfig.app",
            "/tmp/palera1n/",
            "/var/jb/"
        ]
        
        // These files can give false positive in the simulator
        if !isSimulator() {
            paths += [
                "/bin/bash",
                "/usr/sbin/sshd",
                "/usr/libexec/ssh-keysign",
                "/bin/sh",
                "/etc/ssh/sshd_config",
                "/usr/libexec/sftp-server",
                "/usr/bin/ssh"
            ]
        }
        
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                Log.w("Security Warning: \(self) is returning 1.0")
                return 1.0
            }
        }
        
        return 0.0
    }
}
