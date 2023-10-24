//
//  TelephonyCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
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
    
    typealias CarrierInfo = (carrierName: String?, isoCountryCode: String?)
    /// Initializes TelephonyCollector instance
    public init() { }
    
    /// Collects telephony information using CTCarrier
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {

        var result: [String: Any] = [:]
        
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CarrierInfo?
        
        
        if let providers = networkInfo.serviceSubscriberCellularProviders, providers.keys.count > 0 {
            var carriers = providers.map { (carrierName: $0.value.carrierName , isoCountryCode: $0.value.isoCountryCode ) }
            carrier = TelephonyCollector.firstElementInCustomSortedArray(array: carriers)
        }
        
        if let thisCarrier = carrier {
            result["carrierName"] = thisCarrier.carrierName ?? "Unknown"
            result["networkCountryIso"] = thisCarrier.isoCountryCode ?? "Unknown"
        }
        else {
            result["carrierName"] = "Unknown"
            result["networkCountryIso"] = "Unknown"
        }
        
        completion(result)
    }
}


/// Helper Methods
extension TelephonyCollector {
    static func firstElementInCustomSortedArray(array: [CarrierInfo]) -> CarrierInfo? {
        
        let result =  array.sorted {
            if $0.carrierName == nil && $1.carrierName == nil {
                if $0.isoCountryCode == nil {
                    return false
                } else if $1.isoCountryCode == nil {
                    return true
                } else {
                    return $0.isoCountryCode ?? "" < $1.isoCountryCode ?? ""
                }
            } else if $0.carrierName == nil {
                return false
            } else if $1.carrierName == nil {
                return true
            } else {
                return $0.carrierName ?? "" < $1.carrierName ?? ""
            }
        }
        
        return result.first
    }
}
