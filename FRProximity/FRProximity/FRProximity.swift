//
//  FRProximity.swift
//  FRProximity
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

/**
 FRProximity SDK is subset of tools and functionalities consumed by FRAuth SDK related to proximity features (such as location, and BLE) in the device.
 
 ## Note ##
     * FRProximity SDK contains codes that require following privacy consent in application's Info.plist:
        * NSLocationWhenInUseUsageDescription, or
        * NSLocationUsageDescription, or
        * NSLocationAlwaysUsageDescription, or
        * NSLocationAlwaysAndWhenInUseUsageDescription, and
        * NSBluetoothPeripheralUsageDescription
     * FRProximity automatically starts upon FRAuth.start(); FRAuth SDK automatically detects FRProximity presence in the application's bundle, and initiates FRProximity
     * FRProximity does not explicitly request user's permission for above privacy consent; FRProximity simply checks whether the permission has been granted or not, and executes if the permission is granted.
 */
@objc public final class FRProximity: NSObject {
    
    /// Starts FRProximity SDK
    @objc static public func start() {
        FRLog.i("Starting FRProximity SDK")
        FRLog.i("Injecting FRProximity DeviceCollectors")
        // Adds FRProximity's DeviceCollector to central FRDeviceCollector
        FRDeviceCollector.shared.collectors.append(BluetoothCollector())
        FRDeviceCollector.shared.collectors.append(LocationCollector())
    }
}
