// 
//  LocationCollectorTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreLocation
import FRCore

class LocationCollectorTests: FRPBaseTest {
    
    func test_01_basic_init() {
        
        let location = LocationCollector()
        XCTAssertEqual(location.name, "location")
        XCTAssertNotNil(location.locationManager)
        XCTAssertNotNil(location.locationDelegate)
    }

    
    func test_02_location_status_denied() {
        
        let location = FakeLocationCollector()
        location.changeStatus(status: .denied)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertFalse(response.keys.contains("latitude"))
            XCTAssertFalse(response.keys.contains("longitude"))
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_03_location_status_notDetermined() {
        
        let location = FakeLocationCollector()
        location.changeStatus(status: .notDetermined)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertFalse(response.keys.contains("latitude"))
            XCTAssertFalse(response.keys.contains("longitude"))
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_04_location_status_restricted() {
        
        let location = FakeLocationCollector()
        location.changeStatus(status: .restricted)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertFalse(response.keys.contains("latitude"))
            XCTAssertFalse(response.keys.contains("longitude"))
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_05_location_status_authorizedAlways() {
        
        let fakeLocationManager = FakeLocationManager()
        fakeLocationManager.fakeLocation = [CLLocation(latitude: 37.7749, longitude: 122.4194)]
        let location = FakeLocationCollector()
        location.locationManager = fakeLocationManager
        
        
        location.changeStatus(status: .authorizedAlways)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertTrue(response.keys.contains("latitude"))
            XCTAssertTrue(response.keys.contains("longitude"))
            guard let lat = response["latitude"] as? Double, let long = response["longitude"] as? Double else {
                XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                ex.fulfill()
                return
            }
            XCTAssertEqual(lat, 37.7749)
            XCTAssertEqual(long, 122.4194)
        
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_06_location_status_authorizedWhenInUse() {
        
        let fakeLocationManager = FakeLocationManager()
        fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
        let location = FakeLocationCollector()
        location.locationManager = fakeLocationManager
        
        
        location.changeStatus(status: .authorizedWhenInUse)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertTrue(response.keys.contains("latitude"))
            XCTAssertTrue(response.keys.contains("longitude"))
            guard let lat = response["latitude"] as? Double, let long = response["longitude"] as? Double else {
                XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                ex.fulfill()
                return
            }
            XCTAssertEqual(lat, 49.2827)
            XCTAssertEqual(long, 123.1207)
        
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }

    
    func test_07_location_fail_to_fetch_location() {
        
        let fakeLocationManager = FakeLocationManager()
        fakeLocationManager.fakeError = NetworkError.requestFailWithError // fake any error
        let location = FakeLocationCollector()
        location.locationManager = fakeLocationManager
        
        
        location.changeStatus(status: .authorizedWhenInUse)
        let ex = self.expectation(description: "Location collect")
        location.collect { (response) in
            XCTAssertFalse(response.keys.contains("latitude"))
            XCTAssertFalse(response.keys.contains("longitude"))
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
}


class FakeLocationCollector: LocationCollector {
    
    var status: CLAuthorizationStatus = .notDetermined
    func changeStatus(status: CLAuthorizationStatus) {
        self.status = status
    }
    
    override init() {
        super.init()
        self.locationManager = FakeLocationManager()
    }
    
    override var authorizationStatus: CLAuthorizationStatus {
        get {
            return self.status
        }
    }
}


class FakeLocationManager: CLLocationManager {
    
    var fakeError: Error?
    var fakeLocation: [CLLocation]?
        
    override func requestLocation() {
        
        if let error = self.fakeError {
            self.delegate?.locationManager?(self, didFailWithError: error)
        }
        
        if let locations = self.fakeLocation {
            self.delegate?.locationManager?(self, didUpdateLocations: locations)
        }
    }
}
