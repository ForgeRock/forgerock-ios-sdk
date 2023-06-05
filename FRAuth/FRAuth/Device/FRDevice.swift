//
//  FRDevice.swift
//  FRAuth
//
//  Copyright (c) 2019-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// FRDevice represents a device locally managed, and persisted in FRAuth SDK
@objc public class FRDevice: NSObject {

    /// Static FRDeivce instance for singleton
    static var _staticDevice: FRDevice? = nil
    /// FRDeviceIdentifier object responsible for device's instance identifier
    public fileprivate(set) var identifier: FRDeviceIdentifier
    /// Current representation of FRDevice for FRAuth SDK; currentDevice may return nil if SDK was not properly started due to missing configuration file
    @objc public static var currentDevice: FRDevice? {
        get {
            if let device = _staticDevice {
                return device
            }
            else if let frAuth = FRAuth.shared {
                FRLog.v("FRDevice created")
                let device = FRDevice(frAuth)
                _staticDevice = device
                return device
            }
            
            FRLog.w("Invalid SDK State: FRDevice is returning 'nil'.")
            return nil
        }
    }
    
    //  MARK: - Public
    
    /// Collects Device Information with all given DeviceCollector
    ///
    /// - Parameter completion: completion block which returns JSON of all Device Collectors' results
    @objc public func getProfile(completion: @escaping DeviceCollectorCallback) {
        FRDeviceCollector.shared.collect(completion: completion)
    }
    
    
    //  MARK: - Init
    
    /// Initializes FRDevice object with current FRAuth SDK configurations
    ///
    /// - Parameter auth: FRAuth instance for current SDK state
    init(_ auth: FRAuth) {
        self.identifier = FRDeviceIdentifier(keychainService: auth.keychainManager.deviceIdentifierStore)
        super.init()
    }
}
