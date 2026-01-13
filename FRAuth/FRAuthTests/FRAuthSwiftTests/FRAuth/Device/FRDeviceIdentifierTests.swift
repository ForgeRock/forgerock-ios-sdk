//
//  FRDeviceIdentifierTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 - 2025 Ping Identity Corporation. All rights reserved.
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
    
    func testDeviceIdentifierRegenerationFromExistingKey() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Generate initial identifier
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let firstIdentifier = deviceIdentifier.getIdentifier()
        
        // Delete the identifier but keep the keys
        XCTAssertTrue(deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
        
        // Get identifier again - should regenerate from existing key
        let secondIdentifier = deviceIdentifier.getIdentifier()
        
        // Should be the same identifier since it's based on the same key
        XCTAssertEqual(firstIdentifier, secondIdentifier)
    }
    
    func testDeviceIdentifierConsistencyAcrossMultipleCalls() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        
        // Get identifier multiple times
        let identifier1 = deviceIdentifier.getIdentifier()
        let identifier2 = deviceIdentifier.getIdentifier()
        let identifier3 = deviceIdentifier.getIdentifier()
        
        // All should be identical
        XCTAssertEqual(identifier1, identifier2)
        XCTAssertEqual(identifier2, identifier3)
        XCTAssertFalse(identifier1.isEmpty)
    }
    
    func testDeviceIdentifierKeyPairGeneration() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Clean up any existing keys
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        // Verify identifier was generated
        XCTAssertFalse(generatedIdentifier.isEmpty)
        
        // Verify keys were stored
        let publicKeyData = deviceIdentifierKeychain.getData("com.forgerock.ios.device-identifier.pubic-key.data")
        let privateKeyData = deviceIdentifierKeychain.getData("com.forgerock.ios.device-identifier.private-key.data")
        
        XCTAssertNotNil(publicKeyData, "Public key should be stored")
        XCTAssertNotNil(privateKeyData, "Private key should be stored")
        
        // Verify identifier was stored
        let storedIdentifier = deviceIdentifierKeychain.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        XCTAssertEqual(generatedIdentifier, storedIdentifier)
    }
    
    func testDeviceIdentifierHashFormat() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        // SHA1 hash produces 40 hex characters (20 bytes * 2)
        XCTAssertEqual(generatedIdentifier.count, 40, "SHA1 hash should produce 40 hex characters")
        
        // Verify it's all hex characters
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        let identifierCharacterSet = CharacterSet(charactersIn: generatedIdentifier)
        XCTAssertTrue(hexCharacterSet.isSuperset(of: identifierCharacterSet), "Identifier should only contain hex characters")
    }
    
    func testDeviceIdentifierWithCorruptedKeyData() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Store corrupted key data
        let corruptedData = "corrupted".data(using: .utf8)!
        _ = deviceIdentifierKeychain.set(corruptedData, key: "com.forgerock.ios.device-identifier.pubic-key.data")
        
        // Delete identifier to force regeneration
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        // Should still generate an identifier (will hash the corrupted data or generate new keys)
        XCTAssertFalse(generatedIdentifier.isEmpty)
    }
    
    func testDeviceIdentifierCleanupOnFailure() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Clean up any existing data
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")
        
        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        
        // Generate identifier to create keys
        let firstIdentifier = deviceIdentifier.getIdentifier()
        XCTAssertFalse(firstIdentifier.isEmpty)
        
        // Verify initial state
        XCTAssertNotNil(deviceIdentifierKeychain.getData("com.forgerock.ios.device-identifier.pubic-key.data"))
        XCTAssertNotNil(deviceIdentifierKeychain.getData("com.forgerock.ios.device-identifier.private-key.data"))
        XCTAssertNotNil(deviceIdentifierKeychain.getString("com.forgerock.ios.device-identifier.hash-base64-string-identifier"))
        
        // Clean up and regenerate
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")
        
        let secondIdentifier = deviceIdentifier.getIdentifier()
        XCTAssertFalse(secondIdentifier.isEmpty)
        
        // Second identifier should be different since we deleted the keys
        XCTAssertNotEqual(firstIdentifier, secondIdentifier)
    }
    
    func testDeviceIdentifierPersistenceAcrossInstances() {
        
        // Given SDK initialization
        self.startSDK()
        
        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }
        
        // Create first instance and generate identifier
        let deviceIdentifier1 = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let identifier1 = deviceIdentifier1.getIdentifier()
        
        // Create second instance (simulating app restart)
        let deviceIdentifier2 = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let identifier2 = deviceIdentifier2.getIdentifier()
        
        // Should retrieve the same identifier
        XCTAssertEqual(identifier1, identifier2)
    }
    
    func testDeviceIdentifierFallbackToUUID() {
        
        // Given SDK initialization
        self.startSDK()
        
        // Use an invalid keychain service that will fail key generation
        let keychainService = KeychainService(service: "test-service-invalid-\(UUID().uuidString)", accessGroup: "invalid.access.group.\(UUID().uuidString)")
        let deviceIdentifier = FRDeviceIdentifier(keychainService: keychainService)
        
        let generatedIdentifier = deviceIdentifier.getIdentifier()
        
        // Should still generate an identifier using UUID fallback
        XCTAssertFalse(generatedIdentifier.isEmpty)
        XCTAssertEqual(generatedIdentifier.count, 40, "Should still be SHA1 hash format even with UUID")
    }

}
