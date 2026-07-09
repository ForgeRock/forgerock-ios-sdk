//
//  TelephonyCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// TelephonyCollector is responsible for collecting telephony information of the device.
///
/// Note: As of iOS 16, Apple removed access to carrier information (CTCarrier APIs were deprecated
/// with no replacement). This collector now returns "Unknown" for all telephony fields.
public class TelephonyCollector: DeviceCollector {

    /// Name of current collector
    public var name: String = "telephony"

    /// Initializes TelephonyCollector instance
    public init() { }

    /// Collects telephony information
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        result["carrierName"] = "Unknown"
        result["networkCountryIso"] = "Unknown"
        completion(result)
    }
}
