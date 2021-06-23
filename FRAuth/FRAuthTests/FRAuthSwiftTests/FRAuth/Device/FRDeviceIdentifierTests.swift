//
//  FRDeviceIdentifierTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRCore
@testable import FRAuth

class FRDeviceIdentifierTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    func testGeneratedDeviceIdentifierValidation() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        let identifierFromKeychain = deviceIdentifierKeychain.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        
        XCTAssertEqual(generatedIdentifier, identifierFromKeychain)
    }
    
    func testDeviceIdentifierFromKeychainValidation() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Store random UUID as device identifier
        let randomUUID = UUID().uuidString
        XCTAssertTrue(deviceIdentifierKeychain.set(randomUUID, key: "com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        XCTAssertEqual(randomUUID, generatedIdentifier)
    }
    
    func testInvalidKeychainDeviceIdGeneration() {
        
        // Given SDK initialization
        self.startSDK()
        
        // And given invalid Keychain Service with inaccessible AccessGroup
        let keychainService = KeychainService(service: "randomeKeychainService", accessGroup: "randomAccessGroup")
        let deviceIdentifier = FRDeviceIdentifier(keychainService: keychainService)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        // Then, should still be able to generate identifier
        XCTAssertNotNil(generatedIdentifier)
    }

}
