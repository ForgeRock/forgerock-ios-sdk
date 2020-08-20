//
//  LocationCollector.swift
//  FRProximity
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreLocation
import FRAuth

/// LocationCollector is responsible for collecting location information of the device using CLLocationManager.
/// - Note: LocationCollector requests location information by using 'CLLocationManager.requestLocation()' which only retrieves the location once at the time of request. Accuracy of location is 'kCLLocationAccuracyBest' by default, and can be changed through `FRProximity.setLocationAccuracy(accuracy:)`
public class LocationCollector: NSObject, DeviceCollector {
    
    /// FRLocationManager that manages, and collects location authorization, and information
    var locationManager: FRLocationManager = FRLocationManager.shared
    /// Name of current collector
    public var name: String = "location"
    
    /// Collects location information using CLLocationManager
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        //  Requests CLLocation from FRLocationManager
        locationManager.requestLocation { (location) in
            if let location = location {
                var result: [String: Any] = [:]
                result["latitude"] = location.coordinate.latitude
                result["longitude"] = location.coordinate.longitude
                completion(result)
            }
            else {
                completion([:])
            }
        }
    }
}
