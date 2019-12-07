//
//  LocationCollector.swift
//  FRProximity
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreLocation
import FRAuth

/// LocationCollector is responsible for collecting location information of the device using CLLocationManager.
/// - Note: LocationCollector does not explicitly request permission to collect location information. If the application is not authorized to collect location information, then location information will return lon: 0.0, lat: 0.0
/// - Note: LocationCollector requests location information by using 'CLLocationManager.requestLocation()' which only retrieves the location once at the time of request. Accuracy of location is 'kCLLocationAccuracyBest'
class LocationCollector: DeviceCollector {
    
    /// Name of current collector
    var name: String = "location"
    /// CLLocationManager to collect location information
    var locationManager: CLLocationManager = CLLocationManager()
    /// CLLocationManager's delegation class to collect information
    var locationDelegate: LocationManagerDelegation = LocationManagerDelegation()
    
    /// Collects location information using CLLocationManager
    ///
    /// - Parameter completion: completion block
    func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        result["latitude"] = 0.0
        result["longitude"] = 0.0
        // If CLLocationManager's authorization status is not allowed, then do not request location information
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.locationDelegate.completionCallback = completion
            self.locationManager.delegate = self.locationDelegate
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager.requestLocation()
        }
        else {
            completion(result)
        }
    }
}

/// LocationManagerDelegation is responsible for implementation of CLLocationManagerDelegate
class LocationManagerDelegation: NSObject, CLLocationManagerDelegate {
    // Original completion callback received from LocationCollector
    var completionCallback: DeviceCollectorCallback?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let completion = self.completionCallback, let location = locations.last {
            var result: [String: Any] = [:]
            result["latitude"] = location.coordinate.latitude
            result["longitude"] = location.coordinate.longitude
            completion(result)
            self.completionCallback = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let completion = self.completionCallback {
            var result: [String: Any] = [:]
            result["latitude"] = 0.0
            result["longitude"] = 0.0
            completion([:])
            self.completionCallback = nil
        }
    }
}

