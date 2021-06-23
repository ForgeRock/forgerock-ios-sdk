//
//  FRDeviceCollectorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FRDeviceCollectorTests: FRAuthBaseTest {
    
    let kDeviceInfoCurrentVersion = "1.0"
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    func testDeviceCollector() {
        
        // Given SDK start
        self.startSDK()
        
        XCTAssertNotNil(FRDevice.currentDevice)
        XCTAssertNotNil(FRDeviceCollector.shared)
        
        var deviceInfo: [String: Any] = [:]
        let ex = self.expectation(description: "Device Information collect")
        FRDeviceCollector.shared.collect { (result) in
            deviceInfo = result
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Then result must not be nil
        XCTAssertNotNil(deviceInfo)
        
        // Then, validate top level individual result
        guard let _ = deviceInfo["identifier"] as? String, let version = deviceInfo["version"] as? String else {
            XCTFail("Device Identifier, and/or Version information is missing")
            return
        }
        XCTAssertEqual(version, self.kDeviceInfoCurrentVersion)
        
        // Then, validate platform section
        guard let platform = deviceInfo["platform"] as? [String: Any] else {
            XCTFail("Platform section is missing")
            return
        }
        XCTAssertNotNil((platform["version"] as? String))
        XCTAssertNotNil((platform["platform"] as? String))
        XCTAssertNotNil((platform["device"] as? String))
        XCTAssertNotNil((platform["deviceName"] as? String))
        XCTAssertNotNil((platform["locale"] as? String))
        XCTAssertNotNil((platform["timeZone"] as? String))
        XCTAssertNotNil((platform["model"] as? String))
        XCTAssertNotNil((platform["brand"] as? String))
        XCTAssertNotNil((platform["jailBreakScore"] as? Double))
        
//        // Then, validate POSIX info from platform section
//        guard let posix = platform["systemInfo"] as? [String: String] else {
//            XCTFail("systemInfo section within platform is missing")
//            return
//        }
//        XCTAssertNotNil(posix["machine"])
//        XCTAssertNotNil(posix["sysname"])
//        XCTAssertNotNil(posix["release"])
//        XCTAssertNotNil(posix["version"])
//        XCTAssertNotNil(posix["nodename"])
        
        // Then, validate hardware section
        guard let hardware = deviceInfo["hardware"] as? [String: Any] else {
            XCTFail("hardware section is missing")
            return
        }
//        XCTAssertNotNil((hardware["multitaskSupport"] as? Bool))
        XCTAssertNotNil((hardware["cpu"] as? Int))
//        XCTAssertNotNil((hardware["activeCPU"] as? Int))
        XCTAssertNotNil((hardware["memory"] as? Int))
        XCTAssertNotNil((hardware["storage"] as? Int))
        XCTAssertNotNil((hardware["manufacturer"] as? String))
        
        // Then, validate display section from hardware
        guard let display = hardware["display"] as? [String: Any] else {
            XCTFail("display section is missing")
            return
        }
        XCTAssertNotNil((display["orientation"] as? Int))
        XCTAssertNotNil((display["height"] as? Int))
        XCTAssertNotNil((display["width"] as? Int))
        
        // Then, validate camera section from hardware
        guard let camera = hardware["camera"] as? [String: Any] else {
            XCTFail("camera section is missing")
            return
        }
        XCTAssertNotNil((camera["numberOfCameras"] as? Int))
        // For simulator, no camera should be detected
        #if targetEnvironment(simulator)
        XCTAssertEqual((camera["numberOfCameras"] as? Int), 0)
        #endif
        
//        // Then, validate BLE section
//        guard let ble = deviceInfo["bluetooth"] as? [String: Any] else {
//            XCTFail("BLE section is missing")
//            return
//        }
//        XCTAssertNotNil((ble["supported"] as? Bool))
//        // For simulator, BLE should not be supported
//        #if targetEnvironment(simulator)
//        XCTAssertEqual((ble["supported"] as? Bool), false)
//        #endif
        
        // Then, validate Browser section
        guard let browser = deviceInfo["browser"] as? [String: Any] else {
            XCTFail("Browser section is missing")
            return
        }
        XCTAssertNotNil((browser["userAgent"] as? String))
        
        // Then, validate Telephony section
        guard let telephony = deviceInfo["telephony"] as? [String: Any] else {
            XCTFail("Telephony section is missing")
            return
        }
//        XCTAssertNotNil((telephony["mobileCountryCode"] as? String))
//        XCTAssertNotNil((telephony["mobileNetworkCode"] as? String))
        XCTAssertNotNil((telephony["carrierName"] as? String))
        XCTAssertNotNil((telephony["networkCountryIso"] as? String))
//        XCTAssertNotNil((telephony["voipEnabled"] as? Bool))
        // For simulator, telephony section should return following information
        #if targetEnvironment(simulator)
//        XCTAssertEqual((telephony["mobileCountryCode"] as? String), "Unknown")
//        XCTAssertEqual((telephony["mobileNetworkCode"] as? String), "Unknown")
        XCTAssertEqual((telephony["carrierName"] as? String), "Unknown")
        XCTAssertEqual((telephony["networkCountryIso"] as? String), "Unknown")
        #endif
        
        // Then, validate Network section
        guard let network = deviceInfo["network"] as? [String: Any] else {
            XCTFail("Network section is missing")
            return
        }
        XCTAssertNotNil((network["connected"] as? Bool))
        XCTAssertEqual((network["connected"] as? Bool), true)
        
//        // Then, validate Location section
//        guard let location = deviceInfo["location"] as? [String: Any] else {
//            XCTFail("Location section is missing")
//            return
//        }
//        XCTAssertNotNil((location["longitude"] as? Double))
//        XCTAssertNotNil((location["latitude"] as? Double))
    }
    
    func testCustomDeviceCollector() {
        
        // Given SDK start
        self.startSDK()
        
        XCTAssertNotNil(FRDevice.currentDevice)
        XCTAssertNotNil(FRDeviceCollector.shared)
        
        FRDeviceCollector.shared.collectors.append(CustomCollector())
        
        var deviceInfo: [String: Any] = [:]
        let ex = self.expectation(description: "Device Information collect")
        FRDeviceCollector.shared.collect { (result) in
            deviceInfo = result
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Then result must not be nil
        XCTAssertNotNil(deviceInfo)
        
        guard let customInfo = deviceInfo["custom"] as? [String: Any] else {
            XCTFail("Failed to retrieve CustomCollector information")
            return
        }
        
        XCTAssertNotNil((customInfo["custom-key"] as? String))
        XCTAssertTrue((customInfo["custom-key"] as? String) == "custom-value")
    }
}


class CustomCollector: DeviceCollector {
    var name: String = "custom"
    
    func collect(completion: @escaping DeviceCollectorCallback) {
        completion(["custom-key" : "custom-value"])
    }
}
