//
//  FRDeviceTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FRDeviceTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    func testDeviceIdentifierFromKeychain() {
        
        // Given SDK initialization
        self.startSDK()
        
        // Then
        XCTAssertNotNil(FRDevice.currentDevice)
        
        let identifierKey = "com.forgerock.ios.device-identifier.hash-base64-string-identifier"
        let tempDeviceIdentifier = UUID().uuidString
        
        if let deviceIdentifierStore = self.config.keychainManager?.deviceIdentifierStore {
            deviceIdentifierStore.set(tempDeviceIdentifier, key: identifierKey)
            
            XCTAssertEqual(FRDevice.currentDevice?.identifier.getIdentifier(), tempDeviceIdentifier)
        }
        else {
            XCTFail("Failed to retrieve device identifier store")
        }
    }
    
    func testDeviceIdentifierGeneration() {
        
        // Given SDK initialization
        self.startSDK()
        
        // Then
        XCTAssertNotNil(FRDevice.currentDevice)
        XCTAssertNotNil(FRDevice.currentDevice?.identifier)
    }
}
