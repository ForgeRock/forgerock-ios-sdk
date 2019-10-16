//
//  NetworkReachabilityMonitor.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork


/// Network reachability status in String
///
/// - unknown: unknown
/// - reachableWithWiFi: Reachable through WiFi
/// - reachableWithWWAN: Reachable through WWAN; 3G, LTE, and etc
/// - notReachable: Not reachable
enum FRNetworkReachabilityStatus: String {
    case unknown = "Unknown"
    case reachableWithWiFi = "WiFi"
    case reachableWithWWAN = "WWAN"
    case notReachable = "Not reachable"
}

/// Reachability status update callback to notify any status change
typealias ReachabilityStatusUpdateCallback = (_ status: FRNetworkReachabilityStatus) -> Void


/// NetworkReachabilityMonitor class is responsible to monitor current device's network reachability status to a certain host, or generic network reachability
class NetworkReachabilityMonitor {
    
    //  MARK: - Property
    
    /// Reachability object to monitor
    private let reachability: SCNetworkReachability
    /// Boolean indicator whether NetworkReachabilityMonitor is currently monitoring or not
    private var isMonitoring: Bool = false
    /// DispatchQueue of NetworkReachabilityMonitor is currently running
    private var reachabilityQueue: DispatchQueue = DispatchQueue.main
    /// Current reachability status
    var currentStatus: FRNetworkReachabilityStatus
    /// Callback for reachability status change
    var monitoringCallback: ReachabilityStatusUpdateCallback?
    /// Boolean indicator whether network is reachable or not
    var isReachable: Bool {
        get {
            return self.currentStatus == .reachableWithWiFi || self.currentStatus == .reachableWithWWAN
        }
    }

    // MARK: - Init
    
    /// Constructs NetworkReachabilityMonitor with Host
    ///
    /// - Parameter host: String value of Host
    public init?(host: String) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            FRLog.e("NetworkReachabilityMonitor init failure -  host: \(host)")
            return nil
        }
        self.currentStatus = .unknown
        self.reachability = reachability
    }
    
    
    /// Constructs NetworkReachabilityMonitor for generic network reachability
    public init?() {
        var addr = sockaddr()
        addr.sa_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sa_family = sa_family_t(AF_INET)
        
        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &addr) else {
            FRLog.e("NetworkReachabilityMonitor init failure")
            return nil
        }
        
        self.currentStatus = .unknown
        self.reachability = reachability
    }    
    
    
    deinit {
        self.stopMonitoring()
    }
    
    
    // MARK: - Monitoring
    
    /// Starts monitoring reachability
    ///
    /// - Returns: Boolean indicator of whether the monitoring has started or not
    @discardableResult func startMonitoring() -> Bool {
        
        guard !self.isMonitoring else {
            FRLog.v("NetworkReachabilityMonitor is already monitoring network status.")
            return true
        }
        FRLog.i("Start monitoring network reachability")
        self.isMonitoring = true
        
        var cxt = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        cxt.info = Unmanaged.passUnretained(self).toOpaque()
        
        let callbackSet = SCNetworkReachabilitySetCallback(self.reachability, { (_, flags, info) in
            let reachability = Unmanaged<NetworkReachabilityMonitor>.fromOpaque(info!).takeUnretainedValue()
            reachability.updateNetworkReachabilityStatus(flags: flags)
        }, &cxt)
        let queueSet = SCNetworkReachabilitySetDispatchQueue(self.reachability, self.reachabilityQueue)
        
        if !callbackSet || !queueSet {
            FRLog.e("Failed to set SCNetworkReachability callback - callbackSet: \(callbackSet), queueSet: \(queueSet)")
            self.stopMonitoring()
            return false
        }
        
        // Initial status check
        self.reachabilityQueue.async {
            var flags = SCNetworkReachabilityFlags()
            SCNetworkReachabilityGetFlags(self.reachability, &flags)
            self.updateNetworkReachabilityStatus(flags: flags)
        }
        
        return true
    }
    
    
    /// Stops monitoring reachability
    func stopMonitoring() {
        FRLog.i("Stop monitoring network reachability")
        self.isMonitoring = false
        SCNetworkReachabilitySetCallback(self.reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(self.reachability, nil)
    }
    
    
    /// Updates reachability status
    ///
    /// - Parameter flags: SCNetworkReachabilityFlags indicating current network reachability status
    func updateNetworkReachabilityStatus(flags: SCNetworkReachabilityFlags?) {
        self.currentStatus = self.parseReachabilityFlags(flags: flags)
        FRLog.i("Network reachability status update: \(self.currentStatus.rawValue)")
        if let updateCallback = self.monitoringCallback {
            updateCallback(self.currentStatus)
        }
    }
    
    
    /// Parses SCNetworkReachabilityFlags into FRNetworkReachabilityStatus
    ///
    /// - Parameter flags: SCNetworkReachabilityFlags
    /// - Returns: FRNetworkReachabilityStatus
    func parseReachabilityFlags(flags: SCNetworkReachabilityFlags?) -> FRNetworkReachabilityStatus {
        
        guard let currentFlags = flags else {
            return .unknown
        }
        
        if !isReachable(flags: currentFlags) {
            return .notReachable
        }
        else if currentFlags.contains(.isWWAN) {
            return .reachableWithWWAN
        }
        else {
            return .reachableWithWiFi
        }
    }
    
    
    /// Determines whether network is reachable with given SCNetworkReachabilityFlags
    ///
    /// - Parameter flags: SCNetworkReachabilityFalgs
    /// - Returns: Boolean result of whether the network is reachable or not
    func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        
        let isReachable = flags.contains(.reachable)
        let requireConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserIntervention = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!requireConnection || canConnectWithoutUserIntervention)
    }
}

