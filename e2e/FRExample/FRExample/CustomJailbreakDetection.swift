//
//  CustomJailbreakDetection.swift
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit
import Darwin // fork
import MachO // dyld
import ObjectiveC // NSObject and Selector

internal class FileChecker {
    typealias CheckResult = (passed: Bool, failMessage: String)
    
    /**
     Used to store some information provided by statfs()
     */
    struct MountedVolumeInfo {
        let fileSystemName: String
        let directoryName: String
        let isRoot: Bool
        let isReadOnly: Bool
    }
    
    /**
     Used to determine if a file access check should be in Write or Read-Only mode.
     */
    enum FileMode {
        case readable
        case writable
    }
    
    /**
     Given a path, this method provides information about the associated volume.
     - Parameters:
     - path: path is the pathname of any file within the mounted file system.
     - Returns: Returns nil, if statfs() gives a non-zero result.
     */
    private static func getMountedVolumeInfoViaStatfs(
        path: String,
        encoding: String.Encoding = .utf8
    ) -> MountedVolumeInfo? {
        guard let path: [CChar] = path.cString(using: encoding) else {
            assertionFailure("Failed to create a cString with path=\(path) encoding=\(encoding)")
            return nil
        }
        
        var statBuffer = statfs()
        /**
         Upon successful completion, the value 0 is returned; otherwise the
         value -1 is returned and the global variable errno is set to indicate
         the error.
         */
        let resultCode: Int32 = statfs(path, &statBuffer)
        
        if resultCode == 0 {
            let mntFromName: String = withUnsafePointer(to: statBuffer.f_mntfromname) { ptr -> String in
                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
            let mntOnName: String = withUnsafePointer(to: statBuffer.f_mntonname) { ptr -> String in
                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }
            
            return MountedVolumeInfo(fileSystemName: mntFromName,
                                     directoryName: mntOnName,
                                     isRoot: (Int32(statBuffer.f_flags) & MNT_ROOTFS) != 0,
                                     isReadOnly: (Int32(statBuffer.f_flags) & MNT_RDONLY) != 0)
        } else {
            return nil
        }
    }
    
    /**
     This method provides information about all mounted volumes.
     - Returns: Returns nil, if getfsstat() does not return any filesystem statistics.
     */
    private static func getMountedVolumesViaGetfsstat() -> [MountedVolumeInfo]? {
        // If buf is NULL, getfsstat() returns just the number of mounted file systems.
        let count: Int32 = getfsstat(nil, 0, MNT_NOWAIT)
        
        guard count >= 0 else {
            assertionFailure("getfsstat() failed to return the number of mounted file systems.")
            return nil
        }
        
        var statBuffer: [statfs] = .init(repeating: .init(), count: Int(count))
        let size: Int = MemoryLayout<statfs>.size * statBuffer.count
        /**
         Upon successful completion, the number of statfs structures is
         returned. Otherwise, -1 is returned and the global variable errno is
         set to indicate the error.
         */
        let resultCode: Int32 = getfsstat(&statBuffer, Int32(size), MNT_NOWAIT)
        
        if resultCode > -1 {
            if count != resultCode {
                assertionFailure("Unexpected a resultCode=\(resultCode), was expecting=\(count).")
            }
            
            var result: [MountedVolumeInfo] = []
            
            for entry: statfs in statBuffer {
                let mntFromName: String = withUnsafePointer(to: entry.f_mntfromname) { ptr -> String in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
                }
                let mntOnName: String = withUnsafePointer(to: entry.f_mntonname) { ptr -> String in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
                }
                
                let info = MountedVolumeInfo(fileSystemName: mntFromName,
                                             directoryName: mntOnName,
                                             isRoot: (Int32(entry.f_flags) & MNT_ROOTFS) != 0,
                                             isReadOnly: (Int32(entry.f_flags) & MNT_RDONLY) != 0)
                result.append(info)
            }
            
            if count != result.count {
                assertionFailure("Unexpected filesystems count=\(result.count), was expecting=\(count).")
            }
            
            return result
        } else {
            assertionFailure(
                "getfsstat() failed. resultCode=\(resultCode), expected count=\(count) filesystems."
            )
            return nil
        }
    }
    
    /**
     Loops through the mounted volumes provided by Getfsstat() and searches for a match.
     - Parameters:
     - name: The filesystem name or mounted directory name to search for.
     - Returns: Returns nil, if a matching mounted volume is not found.
     */
    private static func getMountedVolumesViaGetfsstat(withName name: String) -> MountedVolumeInfo? {
        if let list = getMountedVolumesViaGetfsstat() {
            if list.count == 0 {
                assertionFailure("Expected to a non-empty list of mounted volumes.")
            } else {
                return list.first(where: { $0.directoryName == name || $0.fileSystemName == name })
            }
        } else {
            assertionFailure("Expected a non-nil list of mounted volumes.")
        }
        return nil
    }
    
    /**
     Uses fopen() to check if an file exists and attempts to open it, in either Read-Only or Read-Write mode.
     - Parameters:
     - path: The file path to open.
     - mode: Determines if the file will be opened in Writable or Read-Only mode.
     - returns: Returns nil, if the file does not exist. Returns true if it can be opened with the given mode.
     */
    static func checkExistenceOfSuspiciousFilesViaFOpen(path: String,
                                                        mode: FileMode) -> CheckResult? {
        // the 'a' or 'w' modes, create the file if it does not exist.
        let mode: String = FileMode.writable == mode ? "r+" : "r"
        
        if let filePointer: UnsafeMutablePointer<FILE> = fopen(path, mode) {
            fclose(filePointer)
            return (false, "Suspicious file exists: \(path)")
        } else {
            return nil
        }
    }
    
    /**
     Uses stat() to check if a file exists.
     - returns: Returns nil, if stat() returns a non-zero result code.
     */
    static func checkExistenceOfSuspiciousFilesViaStat(path: String) -> CheckResult? {
        var statbuf: stat = stat()
        let resultCode = stat((path as NSString).fileSystemRepresentation, &statbuf)
        
        if resultCode == 0 {
            return (false, "Suspicious file exists: \(path)")
        } else {
            return nil
        }
    }
    
    /**
     Uses access() to check whether the calling process can access the file path, in either Read-Only or Write mode.
     - Parameters:
     - path: The file path to open.
     - mode: Determines if the file will be accessed in Write mode or Read-Only mode.
     - returns: Returns nil, if access() returns a non-zero result code.
     */
    static func checkExistenceOfSuspiciousFilesViaAccess(
        path: String,
        mode: FileMode
    ) -> CheckResult? {
        let resultCode = access(
            (path as NSString).fileSystemRepresentation,
            FileMode.writable == mode ? W_OK : R_OK
        )
        
        if resultCode == 0 {
            return (false, "Suspicious file exists: \(path)")
        } else {
            return nil
        }
    }
    
    /**
     Checks if statvfs() considers the given path to be Read-Only.
     - Returns: Returns nil, if statvfs() gives a non-zero result.
     */
    static func checkRestrictedPathIsReadonlyViaStatvfs(
        path: String,
        encoding: String.Encoding = .utf8
    ) -> Bool? {
        guard let path: [CChar] = path.cString(using: encoding) else {
            assertionFailure("Failed to create a cString with path=\(path) encoding=\(encoding)")
            return nil
        }
        
        var statBuffer = statvfs()
        let resultCode: Int32 = statvfs(path, &statBuffer)
        
        if resultCode == 0 {
            return Int32(statBuffer.f_flag) & ST_RDONLY != 0
        } else {
            return nil
        }
    }
    
    /**
     Checks if statvs() considers the volume associated with given path to be Read-Only.
     - Returns: Returns nil, if statfs() does not find the mounted volume.
     */
    static func checkRestrictedPathIsReadonlyViaStatfs(
        path: String,
        encoding: String.Encoding = .utf8
    ) -> Bool? {
        return getMountedVolumeInfoViaStatfs(path: path, encoding: encoding)?.isReadOnly
    }
    
    /**
     Checks if Getfsstat() considers the volume to be Read-Only.
     - Parameters:
     - name: The filesystem name or mounted directory name to search for.
     - Returns: Returns nil, if a matching mounted volume is not found.
     */
    static func checkRestrictedPathIsReadonlyViaGetfsstat(name: String) -> Bool? {
        return self.getMountedVolumesViaGetfsstat(withName: name)?.isReadOnly
    }
}
/// Tuple with check (``FailedCheck``) and failMessage (String)
public typealias FailedCheckType = (check: FailedCheck, failMessage: String)

/// A list of possible checks made by this library
public enum FailedCheck: CaseIterable {
    case urlSchemes
    case existenceOfSuspiciousFiles
    case suspiciousFilesCanBeOpened
    case restrictedDirectoriesWriteable
    case fork
    case symbolicLinks
    case dyld
    case openedPorts
    case pSelectFlag
    case suspiciousObjCClasses
}

public class JailbreakChecker {
    typealias CheckResult = (passed: Bool, failMessage: String)
    
    struct JailbreakStatus {
        let passed: Bool
        let failMessage: String // Added for backwards compatibility
        let failedChecks: [FailedCheckType]
    }
    
    static func isSimulator() -> Bool {
        return checkCompile() || checkRuntime()
    }
    
    static func checkRuntime() -> Bool {
        return ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] != nil
    }
    
    static func checkCompile() -> Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }
    
    static func amIJailbroken() -> Bool {
        return !performChecks().passed
    }
    
    static func amIJailbrokenWithFailMessage() -> (jailbroken: Bool, failMessage: String) {
        let status = performChecks()
        return (!status.passed, status.failMessage)
    }
    
    static func amIJailbrokenWithFailedChecks() -> (jailbroken: Bool,
                                                    failedChecks: [FailedCheckType]) {
        let status = performChecks()
        return (!status.passed, status.failedChecks)
    }
    
    private static func performChecks() -> JailbreakStatus {
        var passed = true
        var failMessage = ""
        var failedChecks: [FailedCheckType] = []
        
        for check in FailedCheck.allCases {
            let result = getResult(from: check)
            
            passed = passed && result.passed
            
            if !result.passed {
                failedChecks.append((check: check, failMessage: result.failMessage))
                
                if !failMessage.isEmpty {
                    failMessage += ", "
                }
            }
            
            failMessage += result.failMessage
        }
        
        return JailbreakStatus(passed: passed, failMessage: failMessage, failedChecks: failedChecks)
        
        func getResult(from check: FailedCheck) -> CheckResult {
            switch check {
            case .urlSchemes:
                return checkURLSchemes()
            case .existenceOfSuspiciousFiles:
                return checkExistenceOfSuspiciousFiles()
            case .suspiciousFilesCanBeOpened:
                return checkSuspiciousFilesCanBeOpened()
            case .restrictedDirectoriesWriteable:
                return checkRestrictedDirectoriesWriteable()
            case .fork:
                if !self.isSimulator() {
                    return checkFork()
                } else {
                    print("App run in the emulator, skipping the fork check.")
                    return (true, "")
                }
            case .symbolicLinks:
                return checkSymbolicLinks()
            case .dyld:
                return checkDYLD()
            case .suspiciousObjCClasses:
                return checkSuspiciousObjCClasses()
            default:
                return (true, "")
            }
        }
    }
    
    private static func canOpenUrlFromList(urlSchemes: [String]) -> CheckResult {
        for urlScheme in urlSchemes {
            if let url = URL(string: urlScheme) {
                if UIApplication.shared.canOpenURL(url) {
                    print("URL scheme detected: \(urlScheme)")
                    return(false, "\(urlScheme) URL scheme detected")
                }
            }
        }
        return (true, "")
    }
    
    // "cydia://" URL scheme has been removed. Turns out there is app in the official App Store
    // that has the cydia:// URL scheme registered, so it may cause false positive
    // "activator://" URL scheme has been removed for the same reason.
    private static func checkURLSchemes() -> CheckResult {
        let urlSchemes = [
            "undecimus://",
            "sileo://",
            "zbra://",
            "filza://"
        ]
        return canOpenUrlFromList(urlSchemes: urlSchemes)
    }
    
    private static func checkExistenceOfSuspiciousFiles() -> CheckResult {
        var paths = [
            "/.cydia_no_stash",
            "/.installed_unc0ver",
            "/Applications/Backgrounder.app",
            "/Applications/Cydia.app",
            "/Applications/FakeCarrier.app",
            "/Applications/FlyJB.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/Snoop-itConfig.app",
            "/Applications/Terminal.app",
            "/Applications/WinterBoard.app",
            "/Applications/blackra1n.app",
            "/Applications/iFile.app",
            "/Applications/iProtect.app",
            "/Applications/palera1n.app",
            "/Applications/Zebra.app",
            "/Library/BawAppie/ABypass",
            "/Library/MobileSubstrate/CydiaSubstrate.dylib",
            "/Library/MobileSubstrate/DynamicLibraries",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.plist",
            "/Library/MobileSubstrate/DynamicLibraries/SBSettings.dylib",
            "/Library/MobileSubstrate/DynamicLibraries/SBSettings.plist",
            "/Library/MobileSubstrate/DynamicLibraries/SSLKillSwitch2.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/Library/PreferenceBundles/Cephei.bundle",
            "/Library/PreferenceBundles/FlyJBPrefs.bundle",
            "/Library/PreferenceBundles/LibertyPref.bundle",
            "/Library/PreferenceBundles/ShadowPreferences.bundle",
            "/Library/PreferenceBundles/SubstitutePrefs.bundle",
            "/Library/PreferenceBundles/libhbangprefs.bundle",
            "/System/Library/LaunchDaemons/com.bigboss.sbsettingsd.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cy@dia.Startup.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/System/Library/PreferenceBundles/CydiaSettings.bundle",
            "/etc/apt",
            "/etc/apt/sources.list.d/electra.list",
            "/etc/apt/sources.list.d/sileo.sources",
            "/etc/apt/undecimus/undecimus.list",
            "/etc/profile.d/terminal.sh",
            "/private/etc/apt",
            "/private/etc/dpkg/origins/debian",
            "/private/etc/profile.d/terminal.sh",
            "/private/etc/ssh/sshd_config",
            "/private/jailbreak.txt",
            "/private/var/Users/",
            "/private/var/cache/apt/",
            "/private/var/lib/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/dpkg/info/cydia-sources.list",
            "/private/var/lib/dpkg/info/cydia.list",
            "/private/var/lib/dpkg/info/mobileterminal.list",
            "/private/var/lib/dpkg/info/mobileterminal.postinst",
            "/private/var/log/syslog",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/tmp/palera1n/",
            "/usr/arm-apple-darwin9",
            "/usr/bin/cycript",
            "/usr/bin/sbsettingsd",
            "/usr/include",
            "/usr/lib/Cephei.framework/Cephei",
            "/usr/lib/libcycript.dylib",
            "/usr/lib/libhooker.dylib",
            "/usr/lib/libjailbreak.dylib",
            "/usr/lib/libsubstitute.dylib",
            "/usr/lib/substrate",
            "/usr/lib/TweakInject",
            "/usr/libexec/cydia",
            "/usr/libexec/cydia/firmware.sh",
            "/usr/share/icu/icudt68l.dat",
            "/usr/share/jailbreak/injectme.plist",
            "/var/binpack",
            "/var/binpack/Applications/loader.app",
            "/var/cache/apt",
            "/var/checkra1n.dmg",
            "/var/db/timezone/icutz",
            "/var/db/timezone/icutz/icutz44l.dat",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/var/lib/dpkg/info/mobileterminal.list",
            "/var/lib/dpkg/info/mobileterminal.postinst",
            "/var/log/apt",
            "/var/log/syslog",
            "/var/mobile/Library/Preferences/me.jjolano.shadow.plist",
            "/var/mobile/Library/SBSettings",
            "/var/tmp/cydia.log"
        ]


        
        // These files can give false positive in the emulator
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
            if FileManager.default.fileExists(atPath: path) {
                print("Suspicious file exists: \(path)")
                return (false, "Suspicious file exists: \(path)")
            } else if let result = FileChecker.checkExistenceOfSuspiciousFilesViaStat(path: path) {
                return result
            } else if let result = FileChecker.checkExistenceOfSuspiciousFilesViaFOpen(
                path: path,
                mode: .readable
            ) {
                return result
            } else if let result = FileChecker.checkExistenceOfSuspiciousFilesViaAccess(
                path: path,
                mode: .readable
            ) {
                return result
            }
        }
        
        return (true, "")
    }
    
    private static func checkSuspiciousFilesCanBeOpened() -> CheckResult {
        var paths = [
            "/.installed_unc0ver",
            "/.bootstrapped_electra",
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/etc/apt",
            "/var/log/apt"
        ]
        
        // These files can give false positive in the emulator
        if !isSimulator() {
            paths += [
                "/bin/bash",
                "/usr/sbin/sshd",
                "/usr/bin/ssh"
            ]
        }
        
        for path in paths {
            if FileManager.default.isReadableFile(atPath: path) {
                print("Suspicious file can be opened: \(path)")
                return (false, "Suspicious file can be opened: \(path)")
            } else if let result = FileChecker.checkExistenceOfSuspiciousFilesViaFOpen(
                path: path,
                mode: .writable
            ) {
                return result
            } else if let result = FileChecker.checkExistenceOfSuspiciousFilesViaAccess(
                path: path,
                mode: .writable
            ) {
                return result
            }
        }
        
        return (true, "")
    }
    
    private static func checkRestrictedDirectoriesWriteable() -> CheckResult {
        let paths = [
            "/",
            "/root/",
            "/private/",
            "/jb/"
        ]
        
        if FileChecker.checkRestrictedPathIsReadonlyViaStatvfs(path: "/") == false {
            print("Restricted path '/' is not Read-Only")
            return (false, "Restricted path '/' is not Read-Only")
        } else if FileChecker.checkRestrictedPathIsReadonlyViaStatfs(path: "/") == false {
            print("Restricted path '/' is not Read-Only")
            return (false, "Restricted path '/' is not Read-Only")
        } else if FileChecker.checkRestrictedPathIsReadonlyViaGetfsstat(name: "/") == false {
            print("Restricted path '/' is not Read-Only")
            return (false, "Restricted path '/' is not Read-Only")
        }
        
        // If library won't be able to write to any restricted directory the return(false, ...) is never reached
        // because of catch{} statement
        for path in paths {
            do {
                let pathWithSomeRandom = path + UUID().uuidString
                try "AmIJailbroken?".write(
                    toFile: pathWithSomeRandom,
                    atomically: true,
                    encoding: String.Encoding.utf8
                )
                // clean if succesfully written
                try FileManager.default.removeItem(atPath: pathWithSomeRandom)
                print("Wrote to restricted path: \(path)")
                return (false, "Wrote to restricted path: \(path)")
            } catch {}
        }
        
        return (true, "")
    }
    
    private static func checkFork() -> CheckResult {
        let pointerToFork = UnsafeMutableRawPointer(bitPattern: -2)
        let forkPtr = dlsym(pointerToFork, "fork")
        typealias ForkType = @convention(c) () -> pid_t
        let fork = unsafeBitCast(forkPtr, to: ForkType.self)
        let forkResult = fork()
        
        if forkResult >= 0 {
            if forkResult > 0 {
                kill(forkResult, SIGTERM)
            }
            print("Fork was able to create a new process (sandbox violation)")
            return (false, "Fork was able to create a new process (sandbox violation)")
        }
        
        return (true, "")
    }
    
    private static func checkSymbolicLinks() -> CheckResult {
        let paths = [
            "/var/lib/undecimus/apt", // unc0ver
            "/Applications",
            "/Library/Ringtones",
            "/Library/Wallpaper",
            "/usr/arm-apple-darwin9",
            "/usr/include",
            "/usr/libexec",
            "/usr/share"
        ]
        
        for path in paths {
            do {
                let result = try FileManager.default.destinationOfSymbolicLink(atPath: path)
                if !result.isEmpty {
                    print("Non standard symbolic link detected: \(path) points to \(result)")
                    return (false, "Non standard symbolic link detected: \(path) points to \(result)")
                }
            } catch {}
        }
        
        return (true, "")
    }
    
    private static func checkDYLD() -> CheckResult {
        let suspiciousLibraries: Set<String> = [
            "systemhook.dylib", // Dopamine - hide jailbreak detection https://github.com/opa334/Dopamine/blob/dc1a1a3486bb5d74b8f2ea6ada782acdc2f34d0a/Application/Dopamine/Jailbreak/DOEnvironmentManager.m#L498
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
        
        for index in 0..<_dyld_image_count() {
            let imageName = String(cString: _dyld_get_image_name(index))
            
            // The fastest case insensitive contains check.
            for library in suspiciousLibraries where imageName.localizedCaseInsensitiveContains(library) {
                print("Suspicious library loaded: \(imageName)")
                return (false, "Suspicious library loaded: \(imageName)")
            }
        }
        
        return (true, "")
    }
    
    private static func checkSuspiciousObjCClasses() -> CheckResult {
        if let shadowRulesetClass = objc_getClass("ShadowRuleset") as? NSObject.Type {
            let selector = Selector(("internalDictionary"))
            if class_getInstanceMethod(shadowRulesetClass, selector) != nil {
                print("Shadow anti-anti-jailbreak detector detected :-)")
                return (false, "Shadow anti-anti-jailbreak detector detected :-)")
            }
        }
        return (true, "")
    }
}
