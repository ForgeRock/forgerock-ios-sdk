//
//  DeviceCollector.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// DeviceCollector protocol is baseline class implementation protocol for FRDeviceCollector's operation
@objc
public protocol DeviceCollector {
    /// Name of collector which will be 'key' value in FRDeviceCollector's result for current DeviceCollector
    @objc
    var name: String { get }
    
    /// Collects Device related information for this particular Device Collector; returned data must be in JSON format, [String: Any].
    ///
    /// - Parameter completion: Completion callback block
    @objc
    func collect(completion: @escaping DeviceCollectorCallback)
}
