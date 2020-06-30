// 
//  BluetoothCollectorTests.swift
//  FRProximityTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import CoreBluetooth

class BluetoothCollectorTests: FRPBaseTest {
    
    func test_01_basic_init() {
        let ble = BluetoothCollector()
        XCTAssertEqual(ble.name, "bluetooth")
        XCTAssertNotNil(ble.manager)
        XCTAssertNotNil(ble.managerDelegate)
    }
    
    
    func test_02_collect() {
        
        let ble = BluetoothCollector()
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            #if targetEnvironment(simulator)
            XCTAssertFalse(isSupported)
            #else
            XCTAssertTrue(isSupported)
            #endif
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_03_collect_unsupported() {
        //  Given
        let ble = BluetoothCollector()
        let fakeManager = FakeManager()
        fakeManager.changeState(state: .unsupported)
        ble.manager = fakeManager
        
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            
            XCTAssertFalse(isSupported)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_04_collect_poweredOff() {
        //  Given
        let ble = BluetoothCollector()
        let fakeManager = FakeManager()
        fakeManager.changeState(state: .poweredOff)
        ble.manager = fakeManager
        
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            
            XCTAssertTrue(isSupported)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_05_collect_resetting() {
        //  Given
        let ble = BluetoothCollector()
        let fakeManager = FakeManager()
        fakeManager.changeState(state: .resetting)
        ble.manager = fakeManager
        
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            
            XCTAssertTrue(isSupported)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_06_collect_unauthorized() {
        //  Given
        let ble = BluetoothCollector()
        let fakeManager = FakeManager()
        fakeManager.changeState(state: .unauthorized)
        ble.manager = fakeManager
        
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            
            XCTAssertFalse(isSupported)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_07_collect_poweredOn() {
        //  Given
        let ble = BluetoothCollector()
        let fakeManager = FakeManager()
        fakeManager.changeState(state: .poweredOn)
        ble.manager = fakeManager
        
        let ex = self.expectation(description: "BLE collect")
        ble.collect { (response) in
            XCTAssertTrue(response.keys.contains("supported"))
            
            guard let isSupported = response["supported"] as? Bool else {
                XCTFail("supported attribute is not Bool as expected")
                return
            }
            
            XCTAssertTrue(isSupported)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
}


class FakeManager: CBPeripheralManager {
    var fakeState: CBManagerState = .unknown
    func changeState(state: CBManagerState) {
        self.fakeState = state
    }
    
    override var state: CBManagerState {
        return self.fakeState
    }
}
