//
//  FRDeviceCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// FRDeviceCollector class manages, and collects Device related information with given DeviceCollector objects and returns JSON result of all Device Collectors
@objc
public class FRDeviceCollector: NSObject {
    /// Singleton instance of FRDeviceCollector
    @objc
    public static let shared = FRDeviceCollector()
    /// An array of DeviceCollector to be collected
    @objc
    public var collectors: [DeviceCollector]
    /// Current version of Device Collector structure
    @objc
    static let FRDeviceCollectorVersion: String = "1.0"
    
    /// Private initialization method which initializes default array of DeviceCollector
    @objc
    public override init() {
        collectors = [
            PlatformCollector(),
            HardwareCollector(),
            BrowserCollector(),
            TelephonyCollector(),
            NetworkCollector()
        ]
    }
    
    /// Collects Device Information with all given DeviceCollector
    ///
    /// - Parameter completion: completion block which returns JSON of all Device Collectors' results
    @objc
    public func collect(completion: @escaping DeviceCollectorCallback) {
        
        var result: [String: Any] = [:]
        
        result["version"] = FRDeviceCollector.FRDeviceCollectorVersion
        if let device = FRDevice.currentDevice {
            result["identifier"] = device.identifier.getIdentifier()
        }
        
        let dispatchGroup = DispatchGroup()
        for collector in self.collectors {
            dispatchGroup.enter()
            collector.collect { (collectedData) in
                if collectedData.keys.count > 0 {
                    result[collector.name] = collectedData
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }
}
