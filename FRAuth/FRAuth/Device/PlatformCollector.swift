//
//  PlatformCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore
import UIKit

/// PlatformCollector is responsible for collecting platform information of the device using UIDevice, and system information.
public class PlatformCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "platform"
    
    /// Initializes PlatformCollector instance
    public init() { }
    
    /// Collects platform information using UIDevice, and system information
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        var result: [String: Any] = [:]
        let jailbreakScore = FRJailbreakDetector.shared.analyze()
        result["platform"] = UIDevice.current.systemName
        result["version"] = UIDevice.current.systemVersion
        result["device"] = UIDevice.current.model
        result["model"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.machine))//parseDeviceIdentifier(identifier: self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.machine)))
        result["locale"] = Locale.current.languageCode
        result["timeZone"] = TimeZone.current.identifier
        result["brand"] = "Apple"
        result["deviceName"] = UIDevice.current.name
        result["jailBreakScore"] = jailbreakScore
        
        var posix: [String: Any] = [:]
        posix["sysname"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.sysname))
        posix["version"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.version))
        posix["release"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.release))
        posix["nodename"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.nodename))
        posix["machine"] = self.convertSysInfo(mirror: Mirror(reflecting: systemInfo.machine))
        
//        result["systemInfo"] = posix
        completion(result)
    }
    
    /// Converts system information into human readable String
    ///
    /// - Parameter mirror: System information attributes
    /// - Returns: String value of system information
    func convertSysInfo(mirror: Mirror) -> String {
        let result = mirror.children.reduce("") { intArr, element in
            guard let value = element.value as? Int8, value != 0 else { return intArr }
            return intArr + String(UnicodeScalar(UInt8(value)))
        }
        return result
    }
    
    /// - TODO: Commenting out to align with sepc, and Android response
//    /// Parses Apple's device model identifier into known device model
//    ///
//    /// - Parameter identifier: String value of Apple's internal device model identifier
//    /// - Returns: Known device model
//    func parseDeviceIdentifier(identifier: String) -> String {
//        #if os(iOS)
//        switch identifier {
//        case "iPod5,1":                                 return "iPod Touch 5"
//        case "iPod7,1":                                 return "iPod Touch 6"
//        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
//        case "iPhone4,1":                               return "iPhone 4s"
//        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
//        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
//        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
//        case "iPhone7,2":                               return "iPhone 6"
//        case "iPhone7,1":                               return "iPhone 6 Plus"
//        case "iPhone8,1":                               return "iPhone 6s"
//        case "iPhone8,2":                               return "iPhone 6s Plus"
//        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
//        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
//        case "iPhone8,4":                               return "iPhone SE"
//        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
//        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
//        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
//        case "iPhone11,2":                              return "iPhone XS"
//        case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
//        case "iPhone11,8":                              return "iPhone XR"
//        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
//        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
//        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
//        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
//        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
//        case "iPad6,11", "iPad6,12":                    return "iPad 5"
//        case "iPad7,5", "iPad7,6":                      return "iPad 6"
//        case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
//        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
//        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
//        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
//        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
//        case "iPad11,1", "iPad11,2":                    return "iPad Mini 5"
//        case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
//        case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
//        case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
//        case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
//        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
//        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
//        case "AppleTV5,3":                              return "Apple TV"
//        case "AppleTV6,2":                              return "Apple TV 4K"
//        case "AudioAccessory1,1":                       return "HomePod"
//        case "i386", "x86_64":                          return "Simulator \(parseDeviceIdentifier(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
//        default:                                        return identifier
//        }
//        #elseif os(tvOS)
//        switch identifier {
//        case "AppleTV5,3": return "Apple TV 4"
//        case "AppleTV6,2": return "Apple TV 4K"
//        case "i386", "x86_64": return "Simulator \(parseDeviceIdentifier(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
//        default: return identifier
//        }
//        #endif
//    }

}
