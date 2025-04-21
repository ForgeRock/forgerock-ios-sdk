// 
//  DeviceProfileCallbackTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreLocation
@testable import FRAuth

class DeviceProfileCallbackTests: FRAuthBaseTest {

    func test_01_callback_execute_all() {
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": true
                },
                {
                    "name": "location",
                    "value": true
                },
                {
                    "name": "message",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertTrue(callback.metadataRequired)
            XCTAssertTrue(callback.locationRequired)
            XCTAssertEqual(callback.message.count, 0)
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            fakeLocationManager.fakeLocation = [CLLocation(latitude: 49.2827, longitude: 123.1207)]
            FakeFRLocationManager.changeStatus(status: .authorizedWhenInUse)
            let location = FakeLocationCollector()
            location.locationManager.locationManager = fakeLocationManager
            location.locationManager.locationManager.delegate = location.locationManager
            callback.collector.collectors.append(location)

            // Assign FakeLocationCollector to callback
            for (index, collector) in callback.collector.collectors.enumerated() {
                if String(describing:collector).contains("FRProximity.LocationCollector") {
                    callback.collector.collectors.remove(at: index)
                }
            }
            
            //  Execute
            var result: [String: Any]?
            let ex = self.expectation(description: "DeviceProfileCallback execute")
            callback.execute { (response) in
                result = response
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let deviceResponse = result else {
                XCTFail("Failed to verify the response of DeviceProfileCallback")
                return
            }
            
            guard let locationResponse = deviceResponse["location"] as? [String: Any], let lat = locationResponse["latitude"] as? Double, let long = locationResponse["longitude"] as? Double else {
                XCTFail("Failed to parse latitude, and longitude in the response; unexpected data type was returned")
                return
            }
            XCTAssertEqual(lat, 49.2827)
            XCTAssertEqual(long, 123.1207)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_callback_execute_all_location_denied() {
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": true
                },
                {
                    "name": "location",
                    "value": true
                },
                {
                    "name": "message",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            try FRAuth.start()
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertTrue(callback.metadataRequired)
            XCTAssertTrue(callback.locationRequired)
            XCTAssertEqual(callback.message.count, 0)
            
            // Fake location collector
            let fakeLocationManager = FakeLocationManager()
            FakeFRLocationManager.changeStatus(status: .denied)
            let location = FakeLocationCollector()
            location.locationManager.locationManager = fakeLocationManager
            location.locationManager.locationManager.delegate = location.locationManager
            callback.collector.collectors.append(location)

            // Assign FakeLocationCollector to callback
            for (index, collector) in callback.collector.collectors.enumerated() {
                if String(describing:collector) == "FRProximity.LocationCollector" {
                    callback.collector.collectors.remove(at: index)
                }
            }
            
            //  Execute
            var result: [String: Any]?
            let ex = self.expectation(description: "DeviceProfileCallback execute")
            callback.execute { (response) in
                result = response
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let deviceResponse = result else {
                XCTFail("Failed to verify the response of DeviceProfileCallback")
                return
            }
            XCTAssertFalse(deviceResponse.keys.contains("location"))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}
