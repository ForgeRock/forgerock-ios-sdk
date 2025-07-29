//
//  FRDeviceCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
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
    public var collectors: [DeviceCollector] = [] // The default array of DeviceCollector is empty, and should be initialized by the ProfileCollector in the DeviceProfileCallback initialization based on the `metadata` and `location` flags
    
    /// Current version of Device Collector structure
    @objc
    static let FRDeviceCollectorVersion: String = "1.0"
    
    
    /// Collects Device Information with all given DeviceCollector
    ///
    /// - Parameter completion: completion block which returns JSON of all Device Collectors' results
    @objc
    public func collect(completion: @escaping DeviceCollectorCallback) {
        
        let dispatchGroup = DispatchGroup()
        let atomicDictionary = AtomicDictionary()
        var result: [String: Any] = [:]
        result["version"] = FRDeviceCollector.FRDeviceCollectorVersion
        if let device = FRDevice.currentDevice {
            result["identifier"] = device.identifier.getIdentifier()
        }
        for collector in self.collectors {
            dispatchGroup.enter()
            collector.collect { (collectedData) in
                atomicDictionary.set(key: collector.name, value: collectedData) {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            let merged = result.merging(atomicDictionary.get(), uniquingKeysWith: { $1 })
            completion(merged)
        }
    }
}
