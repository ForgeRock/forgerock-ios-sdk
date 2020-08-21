// 
//  FRLocationManager.swift
//  FRProximity
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreLocation


/// FRLocationManager is responsible for requesting authorization, managing, and collecting the device's location information using CoreLocation framework
class FRLocationManager: NSObject {
    
    /// typealias definition of CLLocation callback
    typealias LocationCallback = (_ location: CLLocation?) -> Void
    /// Shared singletone instance of FRLocationManager
    static let shared: FRLocationManager = FRLocationManager()
    /// Static constant for time in seconds to cache location information
    static let LOCATION_CACHE_VALIDITY_IN_SEC: Double = 5
    /// CLLocationManager instance to authorize and collect location information
    var locationManager: CLLocationManager = CLLocationManager()
    /// Location information that was most recently collected
    var lastKnownLocation: CLLocation?
    /// Boolean indicator whether or not CLLocationManager should proceed to fetch location after authorization
    var shouldFetchLocation: Bool = false
    /// An array of completion callback to notify upon retrieving location
    var callbacks: [LocationCallback] = []
    /// GCD concurrent queue for atomic property
    let internalQueue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)
    /// Internal Bool indicator of whether or not requesting/authorizing process is in progress
    var inProgress: Bool = false
    /// Instance property of whether or not requesting/authorizing process is in progress
    var isRequesting: Bool {
        get {
            return internalQueue.sync{ inProgress }
        }
        set {
            internalQueue.sync {
                inProgress = newValue
            }
        }
    }
    /// Instance property of authorization status for CLLocationManager
    var authorizationStatus: CLAuthorizationStatus {
        get {
            return CLLocationManager.authorizationStatus()
        }
    }
    /// Human-readable status in String for authorization status
    var authorizationStatusAsString: String {
        switch authorizationStatus {
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        default:
            return "unknown"
        }
    }
    
    
    //  MARK: - Lifecycle
    
    /// Initializes FRLocationManager instance
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
    }
    
    
    //  MARK: - Location Request
    
    /// Requests location information and authorization if needed
    /// - Parameter completion: Completion callback to return location information
    func requestLocation(completion: @escaping LocationCallback) {
        
        //  If CoreLocation service is not enabled, return nil
        guard CLLocationManager.locationServicesEnabled() else {
            FRPLog.w("CoreLocation service is not enabled; returning nil for location request")
            completion(nil)
            return
        }
        
        //  If authorization is already granted
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            // If the location information was fetched in the last <LOCATION_CACHE_VALIDITY_IN_SEC> seconds, return the last known location
            if let lastLocation = lastKnownLocation, (Date().timeIntervalSince1970 - lastLocation.timestamp.timeIntervalSince1970) < FRLocationManager.LOCATION_CACHE_VALIDITY_IN_SEC {
                FRPLog.v("Last fetched location was less than \(FRLocationManager.LOCATION_CACHE_VALIDITY_IN_SEC) seconds; returning cachced location")
                completion(lastKnownLocation)
                return
            }
            
            callbacks.append(completion)
            //  Only request location if the request is not already in the queue
            if !isRequesting {
                FRPLog.v("Location fetch request is started")
                isRequesting = true
                locationManager.requestLocation()
            }
        }
        //  If authorization has not been asked yet
        else if authorizationStatus == .notDetermined {
            FRPLog.v("Location authorization has not been determined yet; requesting authorization")
            callbacks.append(completion)
            //  Run through authorization status check, and make authorization request if needed
            requestAuthorizationIfNeeded()
        }
        //  If authorization has been declined or retricted for the app
        else {
            FRPLog.e("Failed to fetch location information; CLAuthorizationStatus is \(authorizationStatusAsString)")
            completion(nil)
        }
    }
    
    
    /// Requests for CoreLocation service authorization if needed; this method will validate whether or not the application has proper Privacy Consent in the application's `.plist` file and make corresponding request for authorization
    func requestAuthorizationIfNeeded() {
        
        var shouldRequestAlways = false
        var shouldRequestWhenInUse = false
        
        //  For iOS 11, search for NSLocationAlwaysAndWhenInUseUsageDescription, and NSLocationWhenInUseUsageDescription string keys in plist file
        if #available(iOS 11.0, *) {
            shouldRequestAlways = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription") != nil
            shouldRequestWhenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        }
        //  For iOS 11, search for NSLocationAlwaysUsageDescription, and NSLocationWhenInUseUsageDescription string keys in plist file
        else {
            shouldRequestAlways = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil
            shouldRequestWhenInUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        }
        
        //  If Location for Always privacy consent is defined
        if shouldRequestAlways {
            if !isRequesting {
                FRPLog.v("Privacy - Location Always Usage Description is found; requesting for authorization")
                isRequesting = true
                locationManager.requestAlwaysAuthorization()
                shouldFetchLocation = true
            }
        }
        //  If Location for When In Use privacy consent is defined
        else if shouldRequestWhenInUse {
            if !isRequesting {
                FRPLog.v("Privacy - Location When In Use Usage Description is found; requesting for authorization")
                isRequesting = true
                locationManager.requestWhenInUseAuthorization()
                shouldFetchLocation = true
            }
        }
        //  If no privacy consent is defined in .plist, return nil
        else {
            FRPLog.e("Missing Privacy Consent in the application .plist file; SDK cannot proceed for authorization, and returning nil for location information")
            notifyCallbacks(location: nil)
        }
    }
    
    
    /// Notifies an array of Callbacks for the result
    /// - Parameter location: optional CLLocation information that was collected
    func notifyCallbacks(location: CLLocation?) {
        for callback in callbacks {
            callback(location)
        }
        callbacks.removeAll()
    }
}


extension FRLocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        FRPLog.v("CLAuthorizationStatus did changed: \(authorizationStatusAsString)")
        //  Upon completion of authorization, if the location should be fetched
        if shouldFetchLocation {
            //  If authorization is granted, request the location
            if (status == .authorizedAlways || status == .authorizedWhenInUse) {
                locationManager.requestLocation()
            }
            //  otherwise, return nil
            else {
                notifyCallbacks(location: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        FRPLog.v("Location is fetched, and will be cached for \(FRLocationManager.LOCATION_CACHE_VALIDITY_IN_SEC) seconds - \(locations)")
        isRequesting = false
        lastKnownLocation = locations.last
        notifyCallbacks(location: lastKnownLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequesting = false
        notifyCallbacks(location: nil)
        FRPLog.e("Failed to fetch the location information: \(error.localizedDescription)")
    }
}
