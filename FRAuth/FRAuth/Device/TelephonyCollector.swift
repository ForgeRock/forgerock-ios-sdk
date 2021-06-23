//
//  TelephonyCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreTelephony

/// TelephonyCollector is responsible for collecting telephony information of the device using CTCarrier.
public class TelephonyCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "telephony"
    
    /// Initializes TelephonyCollector instance
    public init() { }
    
    /// Collects telephony information using CTCarrier
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {

        var result: [String: Any] = [:]
        
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        
        if #available(iOS 12.0, *) {
            if let providers = networkInfo.serviceSubscriberCellularProviders, providers.keys.count > 0 {
                for (_, thisCarrier) in providers{
                    carrier = thisCarrier
                    break
                }
            }
        }
        else {
            carrier = networkInfo.subscriberCellularProvider
        }
        
        if let thisCarrier = carrier {
            result["carrierName"] = thisCarrier.carrierName ?? "Unknown"
            result["networkCountryIso"] = thisCarrier.isoCountryCode ?? "Unknown"
//            result["mobileNetworkCode"] = thisCarrier.mobileNetworkCode ?? "Unknown"
//            result["mobileCountryCode"] = thisCarrier.mobileCountryCode ?? "Unknown"
//            result["voipEnabled"] = thisCarrier.allowsVOIP
        }
        else {
            result["carrierName"] = "Unknown"
            result["networkCountryIso"] = "Unknown"
//            result["mobileNetworkCode"] = "Unknown"
//            result["mobileCountryCode"] = "Unknown"
//            result["voipEnabled"] = false
        }
        
        completion(result)
    }
}
