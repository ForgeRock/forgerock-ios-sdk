//
//  NetworkCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// NetworkCollector is responsible for collecting network information of the device using FRAuth.NetworkReachabilityMonitor.
public class NetworkCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "network"
    
    /// Initializes NetworkCollector instance
    public init() { }
    
    /// Collects network information using FRAuth.NetworkReachabilityMonitor
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        
        if let reachabilityMonitor = NetworkReachabilityMonitor() {
            reachabilityMonitor.startMonitoring()
            
            reachabilityMonitor.monitoringCallback = { [weak reachabilityMonitor] (status) in
                result["connected"] = reachabilityMonitor?.isReachable
                reachabilityMonitor?.stopMonitoring()
                completion(result)
            }
        }
    }
}
