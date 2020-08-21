//
//  FRProximity.swift
//  FRProximity
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRAuth
import CoreLocation

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
    @objc static public func startProximity() {
        FRPLog.i("Starting FRProximity SDK")
        FRPLog.i("Injecting FRProximity DeviceCollectors")
        // Adds FRProximity's DeviceCollector to central FRDeviceCollector
        FRDeviceCollector.shared.collectors.append(BluetoothCollector())
        FRDeviceCollector.shared.collectors.append(LocationCollector())
    }
    
    
    /// Sets CLLocationAccuracy for LocationCollector
    /// - Parameter accuracy: CLLocationAccuracy that LocationCollector will be using to fetch location
    @objc static public func setLocationAccuracy(accuracy: CLLocationAccuracy) {
        FRLocationManager.shared.locationManager.desiredAccuracy = accuracy
        FRPLog.i("CLLocationAccuracy has changed: \(accuracy)")
    }
}
