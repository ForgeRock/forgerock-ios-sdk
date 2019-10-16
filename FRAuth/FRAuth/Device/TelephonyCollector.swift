//
//  TelephonyCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreTelephony

/// TelephonyCollector is responsible for collecting telephony information of the device using CTCarrier.
class TelephonyCollector: DeviceCollector {
    
    /// Name of current collector
    var name: String = "telephony"
    
    /// Collects telephony information using CTCarrier
    ///
    /// - Parameter completion: completion block
    func collect(completion: @escaping DeviceCollectorCallback) {

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
