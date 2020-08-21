// 
//  FRProximityTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreLocation
@testable import FRAuth

class FRProximityTests: FRPBaseTest {
    
    func test_01_sdk_init() {
        
        do {
            //  Given
            try FRAuth.start()
            var collectors: [String] = []
            for collector in FRDeviceCollector.shared.collectors {
                collectors.append(collector.name)
            }
            
            //  Then
            XCTAssertTrue(collectors.contains("location"))
            XCTAssertTrue(collectors.contains("bluetooth"))
        }
        catch {
            XCTFail("SDK init failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_location_accuracy_default() {
        XCTAssertEqual(FRLocationManager.shared.locationManager.desiredAccuracy, kCLLocationAccuracyHundredMeters)
    }
    
    
    func test_03_update_location_accuracy() {
        FRProximity.setLocationAccuracy(accuracy: kCLLocationAccuracyHundredMeters)
        XCTAssertEqual(FRLocationManager.shared.locationManager.desiredAccuracy, kCLLocationAccuracyHundredMeters)
    }
}
