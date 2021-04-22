//
//  BrowserCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import WebKit

/// BrowserCollector is responsible for collecting browser information of the device.
public class BrowserCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "browser"
    
    /// Initializes BrowserCollector instance
    public init() { }
    
    /// Collects browser information
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        result["userAgent"] = self.buildUserAgent()
        completion(result)
    }
    
    /// Builds custom UserAgent using Application's Bundle information, UIDevice information, ProcessInfo, and other hardware, and platform related information
    /// This meant to be unique per Operating System, Device, and Application
    ///
    /// - Returns: Uniquely generated custom UserAgent for the application, and FRAuth SDK.
    func buildUserAgent() -> String {
        
        var ua = ""
        var sysinfo = utsname()
        uname(&sysinfo)
        var appBuild = "Unknwon"
        var bundleIdentifier = "Unknown"

        if let main = Bundle(for: BrowserCollector.self).infoDictionary {
            if let name = main["CFBundleName"] as? String {
                
                ua += "\(name)"
            }
            
            if let appVersion = main["CFBundleShortVersionString"] as? String {
                if ua.count > 0 {
                    ua += "/"
                }
                ua += "\(appVersion)"
            }
            
            if let appBuildString = main[kCFBundleVersionKey as String] as? String {
                appBuild = appBuildString
            }
            
            if let bundleIdentifierString = main[kCFBundleIdentifierKey as String] as? String {
                bundleIdentifier = bundleIdentifierString
            }
        }
        
        ua += " ("
        
        let currentDevice = UIDevice.current
        
        ua += "\(bundleIdentifier); "
        ua += "\(currentDevice.model); "
        ua += "build:\(appBuild); "
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let deviceVersion = "\(currentDevice.systemName) \(versionString)"
        ua += "\(deviceVersion)"
        
        ua += ")"
        
        if let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary, let version = dictionary["CFBundleShortVersionString"] as? String {
            ua += " CFNetwork/\(version)"
        }
        
        let dv = self.convertSysInfo(mirror: Mirror(reflecting: sysinfo.release))
        ua += " Darwin/\(dv)"
        
        return ua
    }
    
    func convertSysInfo(mirror: Mirror) -> String {
        let result = mirror.children.reduce("") { intArr, element in
            guard let value = element.value as? Int8, value != 0 else { return intArr }
            return intArr + String(UnicodeScalar(UInt8(value)))
        }
        return result
    }
}
