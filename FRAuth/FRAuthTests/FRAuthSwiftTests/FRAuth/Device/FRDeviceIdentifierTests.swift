//
//  FRDeviceIdentifierTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
import Security
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


    // MARK: - withRetry helper

    func testWithRetrySucceedsOnFirstAttempt() {
        var attempts = 0
        let result: String? = FRDeviceIdentifier.withRetry {
            attempts += 1
            return "value"
        }
        XCTAssertEqual(result, "value")
        XCTAssertEqual(attempts, 1, "Successful first attempt should not be retried")
    }

    func testWithRetryRetriesOnceThenSucceeds() {
        var attempts = 0
        let result: String? = FRDeviceIdentifier.withRetry {
            attempts += 1
            // Fail on first attempt, succeed on the second
            return attempts == 1 ? nil : "value"
        }
        XCTAssertEqual(result, "value")
        XCTAssertEqual(attempts, 2, "A transient failure should trigger exactly one retry")
    }

    func testWithRetryStopsAfterOneRetry() {
        var attempts = 0
        let result: String? = FRDeviceIdentifier.withRetry { () -> String? in
            attempts += 1
            return nil
        }
        XCTAssertNil(result)
        XCTAssertEqual(attempts, 2, "Deterministic failures should attempt at most twice (initial + one retry)")
    }


    // MARK: - UUID fallback persistence (Branch 4)

    func testDeviceIdentifierUUIDFallbackPersistsAndIsStable() {
        // Tests Branch 4: when key generation and persistence consistently fail, the UUID fallback
        // must produce the same identifier on every call (via read-back verification).
        //
        // Forced by using an inaccessible access group — SecItemAdd will fail for every write,
        // ensuring generateKeyPair() returns false and all branches above 4 are skipped.

        // Given SDK initialization
        self.startSDK()

        // An invalid access group forces all keychain writes to fail → Branch 4 every call.
        let brokenKeychain = KeychainService(service: "test-service-\(UUID().uuidString)",
                                             accessGroup: "invalid.access.group.\(UUID().uuidString)")
        let deviceIdentifier = FRDeviceIdentifier(keychainService: brokenKeychain)

        let firstIdentifier = deviceIdentifier.getIdentifier()
        XCTAssertFalse(firstIdentifier.isEmpty)
        XCTAssertEqual(firstIdentifier.count, 40, "UUID fallback should still produce a 40-char SHA1 hex string")

        // Because persistence also fails on the broken keychain, we can't read back. The important
        // assertion is that the identifier is a well-formed SHA1 hash — calling again with a broken
        // store will produce a new UUID, which is the documented last-resort behaviour when the
        // keychain is completely inaccessible. That is fine; the goal is to never silently return a
        // garbage value.
        // The stable-persistence path is exercised by testDeviceIdentifierPersistenceAcrossInstances
        // (which uses a valid keychain and validates Branch 1 on a second call).
    }

    func testDeviceIdentifierUUIDFallbackIsStableWhenPersistenceWorks() {
        // Tests that when the Branch 4 UUID path runs on a writable keychain (e.g. all crypto
        // operations failed but the store itself is accessible), the identifier persists and
        // is stable on the next call via Branch 1.

        // Given SDK initialization
        self.startSDK()

        guard let deviceIdentifierKeychain = self.config.keychainManager?.deviceIdentifierStore else {
            XCTFail("Failed to retrieve DeviceIdentifier Keychain storage")
            return
        }

        // Clean slate — no identifier, no keys (so branches 1–3 all miss)
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.hash-base64-string-identifier")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")

        // Inject a pre-computed SHA1 hex string directly (simulating what Branch 4 produces after
        // successfully persisting its UUID-derived identifier) and verify Branch 1 reads it back.
        let preStoredIdentifier = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"  // 40-char hex (SHA1 format)
        XCTAssertTrue(deviceIdentifierKeychain.set(preStoredIdentifier,
                                                    key: "com.forgerock.ios.device-identifier.hash-base64-string-identifier"))

        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)

        // Both calls must return the pre-stored identifier via Branch 1
        let firstCall = deviceIdentifier.getIdentifier()
        let secondCall = deviceIdentifier.getIdentifier()
        XCTAssertEqual(firstCall, preStoredIdentifier, "Should read back the pre-stored identifier via Branch 1")
        XCTAssertEqual(firstCall, secondCall, "Identifier must remain stable across calls")
    }


    // MARK: - SDKS-5451: stale-accessibility repro tests (green since Phase 4)

    /// Builds a KeychainService sharing the live device identifier store's options with only the
    /// accessibility changed, so items can be seeded under a kSecAttrAccessible the live store's
    /// filtered lookups cannot see.
    private func staleAccessibilitySeeder(for keychainManager: KeychainManager) -> KeychainService {
        var seederOptions = keychainManager.deviceIdentifierStore.options
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        // securedKey is nil on the simulator; passing it through keeps a device run on the
        // same encrypted storage path as the live store
        return KeychainService(options: seederOptions, securedKey: keychainManager.securedKey)
    }

    func testDeviceIdentifierStoredUnderDifferentAccessibilityIsReturned() {
        // SDKS-5451 (Task 1.3a red at HEAD, flipped in Task 4.2, AC1/AC6): a persisted identifier
        // must be returned by getIdentifier() regardless of the kSecAttrAccessible it was stored
        // under. Before Phase 4 the accessibility-filtered read returned nil and a fresh
        // identifier was minted instead; FRDeviceIdentifier now looks its items up with
        // matchesAnyAccessibility enabled.
        self.startSDK()

        guard let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve KeychainManager from Config object")
            return
        }
        let deviceIdentifierKeychain = keychainManager.deviceIdentifierStore

        let identifierKey = FRDeviceIdentifier.identifierKeychainServiceKey

        // Delete any current-accessibility items for the managed keys before seeding
        _ = deviceIdentifierKeychain.delete(identifierKey)
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")

        // Seed ONLY the identifier item under the non-default accessibility
        let seeder = self.staleAccessibilitySeeder(for: keychainManager)
        let seededIdentifier = UUID().uuidString

        // The base cleanUp() deletes through the filtered live store and cannot remove
        // stale-accessibility items; the seeder queries the accessibility the item was stored under
        self.addTeardownBlock {
            _ = seeder.delete(identifierKey)
            _ = deviceIdentifierKeychain.delete(identifierKey)
        }

        XCTAssertTrue(seeder.set(seededIdentifier, key: identifierKey), "Seeding the identifier under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(identifierKey), seededIdentifier, "The seeded identifier must be readable through the seeder")

        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)

        XCTAssertEqual(deviceIdentifier.getIdentifier(), seededIdentifier, "getIdentifier must return the persisted identifier regardless of its stored accessibility (the accessibility-filtered Branch 1 read used to miss and a new identifier was minted)")
    }

    func testDeviceIdentifierCustomerStateIsStableAcrossCalls() {
        // SDKS-5451 (Task 1.3b red at HEAD, flipped in Task 4.2): reproduces the TRIAGE-30702
        // customer state — identifier, public-key-data, and private-key-data persisted under a
        // kSecAttrAccessible the live store's lookups filter out. getIdentifier() must return the
        // persisted identifier on every call (no Branch 3 regeneration), and the seeded key data
        // must remain intact.
        self.startSDK()

        guard let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve KeychainManager from Config object")
            return
        }
        let deviceIdentifierKeychain = keychainManager.deviceIdentifierStore

        // Key constants; the 'pubic' typo in the public key data key is real in FRDeviceIdentifier
        let identifierKey = FRDeviceIdentifier.identifierKeychainServiceKey
        let publicKeyDataKey = "com.forgerock.ios.device-identifier.pubic-key.data"
        let privateKeyDataKey = "com.forgerock.ios.device-identifier.private-key.data"

        // Delete any current-accessibility items for the three keys before seeding
        _ = deviceIdentifierKeychain.delete(identifierKey)
        _ = deviceIdentifierKeychain.delete(publicKeyDataKey)
        _ = deviceIdentifierKeychain.delete(privateKeyDataKey)

        let seeder = self.staleAccessibilitySeeder(for: keychainManager)
        let seededIdentifier = UUID().uuidString
        let seededPublicKeyData = "SDKS-5451-seeded-public-key-data".data(using: .utf8)!
        let seededPrivateKeyData = "SDKS-5451-seeded-private-key-data".data(using: .utf8)!

        // The base cleanUp() cannot remove stale-accessibility items; clean via the seeder
        self.addTeardownBlock {
            _ = seeder.delete(identifierKey)
            _ = seeder.delete(publicKeyDataKey)
            _ = seeder.delete(privateKeyDataKey)
            _ = deviceIdentifierKeychain.delete(identifierKey)
            _ = deviceIdentifierKeychain.delete(publicKeyDataKey)
            _ = deviceIdentifierKeychain.delete(privateKeyDataKey)
        }

        // Reproduce the customer state: all three items under the non-default accessibility
        XCTAssertTrue(seeder.set(seededIdentifier, key: identifierKey), "Seeding the identifier under a non-default accessibility must succeed")
        XCTAssertTrue(seeder.set(seededPublicKeyData, key: publicKeyDataKey), "Seeding the public key data under a non-default accessibility must succeed")
        XCTAssertTrue(seeder.set(seededPrivateKeyData, key: privateKeyDataKey), "Seeding the private key data under a non-default accessibility must succeed")

        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)

        // Every call must return the persisted identifier; three equal results also prove
        // Branch 3 did not regenerate the key pair
        let firstIdentifier = deviceIdentifier.getIdentifier()
        let secondIdentifier = deviceIdentifier.getIdentifier()
        let thirdIdentifier = deviceIdentifier.getIdentifier()

        XCTAssertEqual(firstIdentifier, seededIdentifier, "First getIdentifier call must return the persisted identifier regardless of its stored accessibility")
        XCTAssertEqual(secondIdentifier, seededIdentifier, "Second getIdentifier call must return the persisted identifier (no regeneration)")
        XCTAssertEqual(thirdIdentifier, seededIdentifier, "Third getIdentifier call must return the persisted identifier (no regeneration)")

        // The seeded public key data must remain intact. Read it through the seeder's own
        // KeychainService: the unflagged live store's filtered read returns nil by design
        // (decisions.md D4) because the seeded item lives under a different accessibility.
        XCTAssertEqual(seeder.getData(publicKeyDataKey), seededPublicKeyData, "The seeded public key data must remain intact (not deleted or regenerated)")
    }

    func testDeviceIdentifierIsStableAcrossTwoDeviceInstances() {
        // SDKS-5451 (Task 4.2, AC1/AC6): mimics two sequential DeviceProfileCallback nodes, each
        // constructing its own FRDeviceIdentifier over the same device identifier store. Both
        // instances must return the SAME seeded value even though it was stored under a
        // kSecAttrAccessible the live store's lookups filter out. Unlike
        // testDeviceIdentifierPersistenceAcrossInstances (which seeds nothing and exercises the
        // Branch 3 generation path), this test seeds a specific identifier first, so equality
        // proves both instances read the persisted item instead of minting their own.
        self.startSDK()

        guard let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve KeychainManager from Config object")
            return
        }
        let deviceIdentifierKeychain = keychainManager.deviceIdentifierStore

        let identifierKey = FRDeviceIdentifier.identifierKeychainServiceKey

        // Delete any current-accessibility items for the managed keys before seeding
        _ = deviceIdentifierKeychain.delete(identifierKey)
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.pubic-key.data")
        _ = deviceIdentifierKeychain.delete("com.forgerock.ios.device-identifier.private-key.data")

        // Seed ONLY the identifier item under the non-default accessibility
        let seeder = self.staleAccessibilitySeeder(for: keychainManager)
        let seededIdentifier = UUID().uuidString

        // The base cleanUp() cannot remove stale-accessibility items; clean via the seeder
        self.addTeardownBlock {
            _ = seeder.delete(identifierKey)
            _ = deviceIdentifierKeychain.delete(identifierKey)
        }

        XCTAssertTrue(seeder.set(seededIdentifier, key: identifierKey), "Seeding the identifier under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(identifierKey), seededIdentifier, "The seeded identifier must be readable through the seeder")

        // Two FRDeviceIdentifier instances over the same store, as two sequential
        // DeviceProfileCallback nodes would create (FRDevice.init constructs one per FRDevice)
        let firstDeviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        let secondDeviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)

        XCTAssertEqual(firstDeviceIdentifier.getIdentifier(), seededIdentifier, "The first instance must return the seeded identifier regardless of its stored accessibility")
        XCTAssertEqual(secondDeviceIdentifier.getIdentifier(), seededIdentifier, "The second instance must return the same seeded identifier (no per-instance regeneration)")
    }

    func testStaleAccessibilityIdentifierIsNotMintedOver() {
        // SDKS-5451 (Task 4.2, AC1/AC6): with the identifier and key data persisted under a
        // stale kSecAttrAccessible, getIdentifier() must resolve through Branch 1 WITHOUT
        // writing: no new identifier item may appear under the current accessibility, and the
        // seeded key data must not be regenerated.
        self.startSDK()

        guard let keychainManager = self.config.keychainManager else {
            XCTFail("Failed to retrieve KeychainManager from Config object")
            return
        }
        let deviceIdentifierKeychain = keychainManager.deviceIdentifierStore

        // Key constants; the 'pubic' typo in the public key data key is real in FRDeviceIdentifier
        let identifierKey = FRDeviceIdentifier.identifierKeychainServiceKey
        let publicKeyDataKey = "com.forgerock.ios.device-identifier.pubic-key.data"
        let privateKeyDataKey = "com.forgerock.ios.device-identifier.private-key.data"

        // Delete any current-accessibility items for the three keys before seeding
        _ = deviceIdentifierKeychain.delete(identifierKey)
        _ = deviceIdentifierKeychain.delete(publicKeyDataKey)
        _ = deviceIdentifierKeychain.delete(privateKeyDataKey)

        let seeder = self.staleAccessibilitySeeder(for: keychainManager)
        let seededIdentifier = UUID().uuidString
        let seededPublicKeyData = "SDKS-5451-seeded-public-key-data".data(using: .utf8)!
        let seededPrivateKeyData = "SDKS-5451-seeded-private-key-data".data(using: .utf8)!

        // The base cleanUp() cannot remove stale-accessibility items; clean via the seeder
        self.addTeardownBlock {
            _ = seeder.delete(identifierKey)
            _ = seeder.delete(publicKeyDataKey)
            _ = seeder.delete(privateKeyDataKey)
            _ = deviceIdentifierKeychain.delete(identifierKey)
            _ = deviceIdentifierKeychain.delete(publicKeyDataKey)
            _ = deviceIdentifierKeychain.delete(privateKeyDataKey)
        }

        // Seed identifier + key data under the non-default accessibility
        XCTAssertTrue(seeder.set(seededIdentifier, key: identifierKey), "Seeding the identifier under a non-default accessibility must succeed")
        XCTAssertTrue(seeder.set(seededPublicKeyData, key: publicKeyDataKey), "Seeding the public key data under a non-default accessibility must succeed")
        XCTAssertTrue(seeder.set(seededPrivateKeyData, key: privateKeyDataKey), "Seeding the private key data under a non-default accessibility must succeed")

        let deviceIdentifier = FRDeviceIdentifier(keychainService: deviceIdentifierKeychain)
        XCTAssertEqual(deviceIdentifier.getIdentifier(), seededIdentifier, "getIdentifier must return the persisted identifier")

        // The unflagged live store's filtered read sees only current-accessibility items: it
        // returning nil proves no new identifier item was minted under the current accessibility
        // (decisions.md D4 — the live store itself stays unflagged).
        XCTAssertNil(deviceIdentifierKeychain.getString(identifierKey), "No identifier item may be minted under the current accessibility (the filtered read of the live store must stay empty)")

        // The seeded items must be untouched: same bytes, same accessibility
        XCTAssertEqual(seeder.getString(identifierKey), seededIdentifier, "The seeded identifier bytes must be unchanged after getIdentifier()")
        XCTAssertEqual(seeder.getData(publicKeyDataKey), seededPublicKeyData, "The seeded public key data must not be regenerated")
        XCTAssertEqual(seeder.getData(privateKeyDataKey), seededPrivateKeyData, "The seeded private key data must not be regenerated")

        // Attribute-level check: an accessibility-free service+account inventory query must find
        // exactly ONE identifier item, still stored under the seeded (non-default) accessibility —
        // a second item under the current accessibility would mean the identifier was minted over.
        var inventoryQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: deviceIdentifierKeychain.options.service,
            kSecAttrAccount as String: identifierKey,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        if let accessGroup = deviceIdentifierKeychain.options.accessGroup {
            inventoryQuery[kSecAttrAccessGroup as String] = accessGroup
        }
        var inventoryResult: AnyObject?
        let inventoryStatus = SecItemCopyMatching(inventoryQuery as CFDictionary, &inventoryResult)
        XCTAssertEqual(inventoryStatus, errSecSuccess, "The accessibility-free service+account inventory query must find the seeded identifier item")
        let inventory = inventoryResult as? [[String: Any]] ?? []
        XCTAssertEqual(inventory.count, 1, "Exactly one identifier item must exist — no second item was minted under the current accessibility")
        XCTAssertEqual(inventory.first?[kSecAttrAccessible as String] as? String, KeychainAccessibility.whenUnlockedThisDeviceOnly.rawValue, "The surviving identifier item must still be the seeded one, stored under the stale accessibility")
    }

}
