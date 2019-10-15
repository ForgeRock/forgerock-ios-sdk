//
//  NetworkCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// NetworkCollector is responsible for collecting network information of the device using FRAuth.NetworkReachabilityMonitor.
class NetworkCollector: DeviceCollector {
    
    /// Name of current collector
    var name: String = "network"
    
    /// Collects network information using FRAuth.NetworkReachabilityMonitor
    ///
    /// - Parameter completion: completion block
    func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        
        if let reachabilityMonitor = NetworkReachabilityMonitor() {
            reachabilityMonitor.startMonitoring()
            
            reachabilityMonitor.monitoringCallback = { (status) in
                result["connected"] = reachabilityMonitor.isReachable
                reachabilityMonitor.stopMonitoring()
                completion(result)
            }
        }
    }
}
