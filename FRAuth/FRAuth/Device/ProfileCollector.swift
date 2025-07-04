// 
//  ProfileCollector.swift
//  FRAuth
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

public class ProfileCollector: DeviceCollector {
    
    public var name: String = "metadata"
    
    /// An array of DeviceCollector to be collected
    public var collectors: [DeviceCollector]
    
    /// Initialization method which initializes default array of ProfileCollector
    public init() {
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
        
        let dispatchGroup = DispatchGroup()
        let atomicDictionary = AtomicDictionary()
        for collector in self.collectors {
            dispatchGroup.enter()
                collector.collect { (collectedData) in
                    atomicDictionary.set(key: collector.name, value: collectedData) {
                        dispatchGroup.leave()
                    }
                }
        }
        dispatchGroup.notify(queue: .main) {
            completion(atomicDictionary.get())
        }
    }
}

