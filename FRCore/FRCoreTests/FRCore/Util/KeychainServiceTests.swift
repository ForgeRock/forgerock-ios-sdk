//
//  KeychainServiceTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class KeychainServiceTests: FRBaseTestCase {

    var kc: KeychainService?
    
    override func setUp() {
        self.configFileName = "Config-live-01"
        super.setUp()
    }
    
    override func tearDown() {
        // Delete all items upon tear down, if KeychainService exists
        self.kc?.deleteAll()
    }
    
    func testKeychainServiceTeamId() {
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }
        
        // 1. Create Keychain Service with accessGroup (Shared Keychain Identifier as defined in XCode Capabilities tab) only
        let kc = KeychainService(service: "com.forgerock.ios", accessGroup: accessGroup)
        XCTAssertTrue(kc.debugDescription.contains(".com.bitbar.*"))
        
        // 2. Create Keychain Service with accessGroup and Apple TeamID; 'JV6EC9KSN3' is ForgeRock Ltd's TeamID
        let kc2 = KeychainService(service: "com.forgerock.ios", accessGroup: "JV6EC9KSN3.\(accessGroup)")
        XCTAssertTrue(kc2.debugDescription.contains("JV6EC9KSN3.\(accessGroup)"))
    }
    
    func testKeychainServiceAccessGroup() {
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }
        
        // 1. Validate if granted AccessGroup is correctly validated with Apple TeamID; validation requires AccessGroup contains Apple TeamID
        XCTAssertTrue(KeychainService.validateAccessGroup(service: "com.forgerofck.ios", accessGroup: "9QSE66762D.\(accessGroup)"))
        
        // 2. Validate if AccessGroup that is not valid Keychain Sharing identifier
        XCTAssertFalse(KeychainService.validateAccessGroup(service: "com.forgerofck.ios", accessGroup: "com.forgerock.ios.notvalid"))
    }
    
    func testKeychainString() {
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        // 1. Set String value
        // 2. Validate if correct value was stored
        // 3. Validate if the vlaue was deleted
        XCTAssertTrue(kc.set("test-value", key: "test-key"))
        XCTAssertEqual(kc.getString("test-key"), "test-value")
        XCTAssertTrue(kc.delete("test-key"))
        XCTAssertNil(kc.getString("test-key"))
        
        // 1. Set String value with a key
        // 2. Validate if correct value was stored
        // 3. Set another String value with different key
        // 4. Validate if the value was correctly updated
        // 5. Delete the value, and validate
        XCTAssertTrue(kc.set("test-value-1", key: "test-key"))
        XCTAssertEqual(kc.getString("test-key"), "test-value-1")
        XCTAssertTrue(kc.set("test-value-2", key: "test-key"))
        XCTAssertEqual(kc.getString("test-key"), "test-value-2")
        XCTAssertTrue(kc.delete("test-key"))
        XCTAssertNil(kc.getString("test-key"))
    }
    
    func testKeychainBool() {
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        // 1. Set Bool value
        // 2. Validate if correct value was stored
        // 3. Validate if the vlaue was deleted
        XCTAssertTrue(kc.set(true, key: "true-key"))
        
        if let boolVal = kc.getBool("true-key") {
            if !boolVal {
                XCTFail("Failed to restore correct Bool value")
            }
        } else {
            XCTFail("Failed to restore Bool value")
        }
        XCTAssertTrue(kc.delete("true-key"))
        XCTAssertNil(kc.getBool("true-key"))
        
        // 1. Set Bool value with a key
        // 2. Validate if correct value was stored
        // 3. Set another Bool value with different key
        // 4. Validate if the value was correctly updated
        // 5. Delete the value, and validate
        XCTAssertTrue(kc.set(true, key: "test-key"))
        if let boolVal = kc.getBool("test-key") {
            if !boolVal {
                XCTFail("Failed to restore correct Bool value")
            }
        } else {
            XCTFail("Failed to restore Bool value")
        }
        XCTAssertTrue(kc.set(false, key: "test-key"))
        if let boolVal = kc.getBool("test-key") {
            if boolVal {
                XCTFail("Failed to restore correct Bool value")
            }
        } else {
            XCTFail("Failed to restore Bool value")
        }
        XCTAssertTrue(kc.delete("true-key"))
        XCTAssertNil(kc.getBool("true-key"))
    }
    
    func testKeychainData() {
        guard let testData = "test-base64-string-data".data(using: .utf8), let testData2 = "test-base64-string-data-2".data(using: .utf8) else {
            XCTFail("Failed to generate test Data object")
            return
        }
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        // 1. Set Data value
        // 2. Validate if correct value was stored
        // 3. Validate if the vlaue was deleted
        XCTAssertTrue(kc.set(testData, key: "test-key"))
        XCTAssertEqual(kc.getData("test-key"), testData)
        XCTAssertTrue(kc.delete("test-key"))
        XCTAssertNil(kc.getData("test-key"))
        
        // 1. Set Data value with a key
        // 2. Validate if correct value was stored
        // 3. Set another Data value with different key
        // 4. Validate if the value was correctly updated
        // 5. Delete the value, and validate
        XCTAssertTrue(kc.set(testData, key: "test-key-1"))
        XCTAssertEqual(kc.getData("test-key-1"), testData)
        XCTAssertTrue(kc.set(testData2, key: "test-key-1"))
        XCTAssertEqual(kc.getData("test-key-1"), testData2)
        XCTAssertTrue(kc.delete("test-key-1"))
        XCTAssertNil(kc.getData("test-key-1"))
    }
    
    func testKeychainKeys() {
        
        // Reference: https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/generating_new_cryptographic_keys
        let tag = "com.forgerock.ios.keys-1".data(using: .utf8)!
        let attributes: [String: Any] =
            [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String:      4096,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String:    true,
                 kSecAttrApplicationTag as String: tag]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error), let publicKey = SecKeyCopyPublicKey(privateKey) else {
            XCTFail("Failed to generate keypair for testing" + error!.takeRetainedValue().localizedDescription)
            return
        }
        
        let tag2 = "com.forgerock.ios.keys-1".data(using: .utf8)!
        let attributes2: [String: Any] =
            [kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits as String:      4096,
             kSecPrivateKeyAttrs as String:
                [kSecAttrIsPermanent as String:    true,
                 kSecAttrApplicationTag as String: tag2]
        ]
        
        var error2: Unmanaged<CFError>?
        guard let privateKey2 = SecKeyCreateRandomKey(attributes2 as CFDictionary, &error2), let publicKey2 = SecKeyCopyPublicKey(privateKey2) else {
            XCTFail("Failed to generate keypair for testing" + error2!.takeRetainedValue().localizedDescription)
            return
        }
        
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        XCTAssertTrue(kc.setRSAKey(publicKey, applicationTag: "fr.publicKey"))
        XCTAssertTrue(kc.setRSAKey(privateKey, applicationTag: "fr.privateKey"))
        
        XCTAssertEqual(kc.getRSAKey("fr.publicKey"), publicKey)
        XCTAssertEqual(kc.getRSAKey("fr.privateKey"), privateKey)
        
        
        XCTAssertTrue(kc.setRSAKey(publicKey2, applicationTag: "fr.publicKey"))
        XCTAssertTrue(kc.setRSAKey(privateKey2, applicationTag: "fr.privateKey"))
        
        XCTAssertEqual(kc.getRSAKey("fr.publicKey"), publicKey2)
        XCTAssertEqual(kc.getRSAKey("fr.privateKey"), privateKey2)
        
        XCTAssertTrue(kc.delete("fr.publicKey", itemClass: .key))
        XCTAssertTrue(kc.delete("fr.privateKey", itemClass: .key))
        XCTAssertNil(kc.getRSAKey("fr.publicKey"))
        XCTAssertNil(kc.getRSAKey("fr.privateKey"))
    }
    
    
    func testKeychainCertificateAndIdentity() {
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        // 1. Read certificate, store, and validate
        guard let cert1 = self.readCert(fileName: "02-cert", ext: "pem") else {
            XCTFail("Failed to retrieve cert data from TestData")
            return
        }
        XCTAssertTrue(kc.setCertificate(cert1, label: "thisCert"))
        XCTAssertEqual(kc.getCertificate("thisCert"), cert1)
        
        // 2. Read another certificate, store, and validate
        guard let cert = self.readCert(fileName: "01-cert", ext: "cert") else {
            XCTFail("Failed to retrieve cert data from TestData")
            return
        }
        XCTAssertTrue(kc.setCertificate(cert, label: "thisCert"))
        XCTAssertEqual(kc.getCertificate("thisCert"), cert)
        
        // 3. Make sure that there is no identity retrieved from keychain
        XCTAssertNil(kc.getIdentities("thisCert"))
        
        // 4. Read private key, store, and validate
        guard let pKey = self.readPrivateKey(fileName: "01-pkey", ext: "key") else {
            XCTFail("Failed to retrieve private key data from TestData")
            return
        }
        XCTAssertTrue(kc.setRSAKey(pKey, applicationTag: "privateKey"))
        XCTAssertEqual(kc.getRSAKey("privateKey"), pKey)
        
        // 5. Validate if identity is retrieved; identity is a combination of certificate, and associated private key stored in the keychain
        XCTAssertNotNil(kc.getIdentities("thisCert"))
        
        // 6. Delete items
        XCTAssertTrue(kc.delete("thisCert", itemClass: .certificate))
        XCTAssertTrue(kc.delete("privateKey", itemClass: .key))
    }
    
    func testKeychainAllItems() {
        guard let testData = "test-base64-string-data".data(using: .utf8), let testData2 = "test-base64-string-data-2".data(using: .utf8) else {
            XCTFail("Failed to generate test Data object")
            return
        }
        
        let kc = KeychainService(service: "com.forgerock.ios")
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        
        let testDataDict: [String: Any] = ["test-data-1": testData, "test-data-2": testData2, "test-str-key-1": "test-str-1", "test-str-key-2": "test-str-2", "bool-false-key": false, "bool-true-key": true]
        
        for (key, val) in testDataDict {
            if val is Bool {
                kc.set(val as! Bool, key: key)
            }
            else if val is String {
                kc.set(val as? String, key: key)
            }
            else if val is Data {
                kc.set(val as! Data, key: key)
            }
        }
        
        guard let allItems = kc.allItems() else {
            XCTFail("Failed to retrieve all items while expecting some returns")
            return
        }
        print(kc.debugDescription)
        XCTAssertEqual(testDataDict.keys.count, allItems.keys.count)
//
//        for (key, val) in allItems {
//
//            if let thisTestData = testDataDict[key] {
//                if val is Bool {
//                    XCTAssertTrue(isEqual(type: Bool.self, a: thisTestData, b: val))
//                }
//                else if val is String {
//                    XCTAssertTrue(isEqual(type: String.self, a: thisTestData, b: val))
//                }
//                else if val is Data {
//                    XCTAssertTrue(isEqual(type: Data.self, a: thisTestData, b: val))
//                }
//            }
//            else {
//                XCTFail("Unexpected data was returned from allItems()")
//            }
//        }
    }
    
    func isEqual<T: Equatable>(type: T.Type, a: Any, b: Any) -> Bool {
        guard let a = a as? T, let b = b as? T else { return false }
        return a == b
    }
    
    func readCert(fileName: String, ext: String) -> SecCertificate? {
        
        var certAsString: String = ""
        if let certPath = Bundle(for: KeychainServiceTests.self).path(forResource: fileName, ofType: ext), var certString = try? String(contentsOfFile: certPath) {
            certString = certString.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            certString = certString.replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            certString = certString.replacingOccurrences(of: "\n", with: "")
            certAsString = certString
        } else {
            return nil
        }
        
        guard let certData = Data(base64Encoded: certAsString), let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
            return nil
        }
        
        return cert
    }
    
    func readPrivateKey(fileName: String, ext: String) -> SecKey? {
        
        var keyAsString: String = ""
        if let keyPath = Bundle(for: KeychainServiceTests.self).path(forResource: fileName, ofType: ext), var keyString = try? String(contentsOfFile: keyPath) {
            keyString = keyString.replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            keyString = keyString.replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            keyString = keyString.replacingOccurrences(of: "\n", with: "")
            keyAsString = keyString
        } else {
            return nil
        }
        
        guard let keyData = Data(base64Encoded: keyAsString) else {
            return nil
        }
        
        let sizeInBits = keyData.count * 8
        let attributes: [String: Any] = [
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: NSNumber(value: sizeInBits)
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            return nil
        }
        
        return privateKey
    }
    
      // MARK: - Test deleteAll does not delete customer RSA keys

    func test_deleteAll_shouldNotDeleteCustomerRSAKeys() {
        // Given: Create a customer's RSA key (not created by SDK)
        let customerKeyTag = "com.customer.app.rsaKey"
        let customerKeyIdentifier = customerKeyTag.data(using: .utf8)!
        
        // Generate RSA key pair for customer
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock as String,
                kSecAttrApplicationTag as String: customerKeyIdentifier
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) != nil else {
            XCTFail("Failed to create customer RSA key: \(String(describing: error))")
            return
        }
        
        // Verify customer key exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag as String: customerKeyIdentifier,
            kSecReturnRef as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock as String
        ]
        
        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)
        XCTAssertEqual(status, errSecSuccess, "Customer key should exist before deleteAll")
        
        // When: Call deleteAll on KeychainService
        let keychainService = KeychainService(service: "com.forgerock.ios.test")
        keychainService.deleteAll()
        
        // Then: Customer's RSA key should still exist
        item = nil
        status = SecItemCopyMatching(query as CFDictionary, &item)
        XCTAssertEqual(status, errSecSuccess, "Customer RSA key should NOT be deleted by SDK")
        
        // Cleanup: Delete customer key
        SecItemDelete(query as CFDictionary)
    }


    // MARK: - Test decrypt-failure returns nil instead of raw encrypted blob

    func test_getData_withUndecryptableValue_returnsNil() {
        guard SecuredKey.isAvailable() else {
            // SecuredKey-backed encryption is required for this scenario
            return
        }

        let service = "com.forgerock.ios.test.decryptFailure"
        let key = "encrypted-test-key"
        let tag1 = "com.forgerock.ios.test.securedKey.decryptA.\(UUID().uuidString)"
        let tag2 = "com.forgerock.ios.test.securedKey.decryptB.\(UUID().uuidString)"

        guard let securedKeyA = SecuredKey(applicationTag: tag1), let securedKeyB = SecuredKey(applicationTag: tag2) else {
            XCTFail("Failed to generate SecuredKey instances")
            return
        }

        // Given: data stored encrypted with SecuredKey A
        let kcA = KeychainService(service: service, securedKey: securedKeyA)
        self.kc = kcA
        XCTAssertTrue(kcA.set("super-secret-value", key: key))
        XCTAssertEqual(kcA.getString(key), "super-secret-value")

        // When: the same stored item is read with a different SecuredKey B (cannot decrypt)
        let kcB = KeychainService(service: service, securedKey: securedKeyB)

        // Then: getData/getString must return nil rather than the raw (still-encrypted) bytes
        XCTAssertNil(kcB.getData(key), "Undecryptable data must be treated as not found, not returned as raw encrypted bytes")
        XCTAssertNil(kcB.getString(key), "Undecryptable data must not be decodable to a String")
    }


    // MARK: - SDKS-5451: Keychain accessibility semantics probe

    func test_platform_accessibilityFiltersLookups_butNotDuplicateDetection() {
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }

        guard let appleTeamId = KeychainService.getAppleTeamId() else {
            XCTFail("Failed to retrieve Apple Team ID")
            return
        }

        // Raw Security.framework probe (no SDK code): confirms in this environment that
        // kSecAttrAccessible acts as a lookup filter (SecItemCopyMatching returns
        // errSecItemNotFound) while SecItemAdd still detects duplicates on
        // class+service+account(+accessGroup) only (errSecDuplicateItem). This test passes
        // at HEAD and stays permanently as a tripwire for Apple changing the semantics
        // SDKS-5451's fix relies on (AC7).
        self.runSDKS5451AccessibilityProbe(service: "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)", accessGroup: nil)
        self.runSDKS5451AccessibilityProbe(service: "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)", accessGroup: appleTeamId + "." + accessGroup)
    }

    private func runSDKS5451AccessibilityProbe(service: String, accessGroup: String?) {
        let account = "SDKS-5451.probe.account"
        let valueData = "SDKS-5451-probe-value".data(using: .utf8)!
        let accessibilityA = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        let accessibilityB = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String

        // Accessibility-free delete query; also used as the identity base for the adds below
        var deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup = accessGroup {
            deleteQuery[kSecAttrAccessGroup as String] = accessGroup
        }
        // Cleanup with an accessibility-free query, regardless of how the probe ends
        defer {
            SecItemDelete(deleteQuery as CFDictionary)
        }

        // 1. Store the item under accessibility A
        var addQueryA = deleteQuery
        addQueryA[kSecValueData as String] = valueData
        addQueryA[kSecAttrAccessible as String] = accessibilityA
        XCTAssertEqual(SecItemAdd(addQueryA as CFDictionary, nil), errSecSuccess, "Seeding under accessibility A must succeed (accessGroup: \(accessGroup ?? "nil"))")

        // 2. Lookup filtered by accessibility B must NOT see the item (accessibility is a filter)
        var lookupQueryB = deleteQuery
        lookupQueryB[kSecAttrAccessible as String] = accessibilityB
        XCTAssertEqual(SecItemCopyMatching(lookupQueryB as CFDictionary, nil), errSecItemNotFound, "Lookup with a different accessibility must be filtered out (accessGroup: \(accessGroup ?? "nil"))")

        // 3. Adding the same identity under accessibility B must be rejected as duplicate
        // (duplicate detection ignores the accessibility attribute)
        var addQueryB = addQueryA
        addQueryB[kSecAttrAccessible as String] = accessibilityB
        XCTAssertEqual(SecItemAdd(addQueryB as CFDictionary, nil), errSecDuplicateItem, "SecItemAdd must detect the duplicate regardless of the accessibility attribute (accessGroup: \(accessGroup ?? "nil"))")

        // 4. Accessibility-free lookup must find the stored item
        XCTAssertEqual(SecItemCopyMatching(deleteQuery as CFDictionary, nil), errSecSuccess, "Accessibility-free lookup must find the stored item (accessGroup: \(accessGroup ?? "nil"))")
    }


    // MARK: - SDKS-5451: stale-accessibility replace (AC2, fixed by the Phase 3 self-heal)

    func test_set_overItemStoredUnderDifferentAccessibility_succeedsAndReplacesValue() {
        // SDKS-5451 (Task 1.2, AC2): set() must replace an item stored under a different
        // kSecAttrAccessible. Before the Phase 3 self-heal the existence check and the
        // replace-path delete were accessibility-filtered (errSecItemNotFound / -25300) while
        // SecItemAdd still detected the duplicate (errSecDuplicateItem / -25299), so set()
        // returned false; addItem(_:key:itemClass:) now recovers once from the duplicate.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.replace.key"

        // Seeder stores the conflicting item under a non-default accessibility
        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        // The class tearDown's deleteAll() is accessibility-filtered and cannot remove the
        // stale item; the seeder queries the accessibility the item was stored under.
        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        // Seed the conflicting item
        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "v1", "The seeded item must be readable through the seeder")

        // Default service (kSecAttrAccessibleAfterFirstUnlock) writes over the item
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        XCTAssertTrue(kc.set("v2", key: key), "set must replace the item stored under a different accessibility (previously: existence check returned -25300, then SecItemAdd returned -25299)")
        XCTAssertEqual(kc.getString(key), "v2", "The replaced value must be readable through the writing service")
        XCTAssertNil(seeder.getString(key), "Exactly one item must remain after the replace; the stale-accessibility item must be gone")
    }


    // MARK: - SDKS-5451: accessibility-free lookup query shape (Task 2.3, keychain-free)

    func test_buildLookupQuery_defaultOptions_keepAccessibilityFilterForAllClasses() {
        // Regression guard for every other Keychain consumer: with the default options
        // (matchesAnyAccessibility == false) lookups must stay accessibility-filtered for
        // every item class, exactly as before SDKS-5451 (D5).
        let options = KeychainOptions(service: "com.forgerock.ios.test.SDKS-5451.queryshape")
        XCTAssertFalse(options.matchesAnyAccessibility, "matchesAnyAccessibility must default to false")

        for itemClass in [KeychainItemClass.genericPassword, .internetPassword, .certificate, .key, .securedKey, .identity] {
            let query = options.buildLookupQuery(itemClass)
            XCTAssertEqual(query[kSecAttrAccessible as String] as? String, options.accessibility.rawValue, "Default options must keep the accessibility filter in the lookup query (class: \(itemClass))")
        }
    }

    func test_buildLookupQuery_matchesAnyAccessibility_dropsFilterOnlyForGenericPassword() {
        var options = KeychainOptions(service: "com.forgerock.ios.test.SDKS-5451.queryshape")
        options.matchesAnyAccessibility = true

        // Flagged: the accessibility filter is dropped for .genericPassword only
        let genericQuery = options.buildLookupQuery(.genericPassword)
        XCTAssertNil(genericQuery[kSecAttrAccessible as String], "Flagged options must drop the accessibility filter from the genericPassword lookup query")

        // Non-generic classes keep the filter; their queries are not fully identity-bound,
        // so dropping the filter would make lookups match unrelated items (D5)
        for itemClass in [KeychainItemClass.internetPassword, .certificate, .key, .securedKey, .identity] {
            let query = options.buildLookupQuery(itemClass)
            XCTAssertEqual(query[kSecAttrAccessible as String] as? String, options.accessibility.rawValue, "Non-generic classes must keep the accessibility filter even when flagged (class: \(itemClass))")
        }
    }

    func test_buildLookupQuery_matchesAnyAccessibility_keepsClassServiceAccessGroupAndSynchronizable() {
        // Pins AC2's synchronizable-preservation clause: relaxing only the accessibility
        // filter must not drop any other identity attribute of the lookup query.
        let service = "com.forgerock.ios.test.SDKS-5451.queryshape"
        let accessGroup = "SDKS-5451.test.accessgroup"

        var options = KeychainOptions(service: service, accessGroup: accessGroup)
        options.matchesAnyAccessibility = true
        options.synchronizable = true

        let query = options.buildLookupQuery(.genericPassword)

        XCTAssertEqual(query[kSecClass as String] as? String, KeychainItemClass.genericPassword.rawValue, "The item class must survive the accessibility-free lookup query")
        XCTAssertEqual(query[kSecAttrService as String] as? String, service, "The service attribute must survive the accessibility-free lookup query")
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, options.accessGroup, "The (team-prefixed) access group must survive the accessibility-free lookup query")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, true, "kSecAttrSynchronizable must survive the accessibility-free lookup query")
        XCTAssertNil(query[kSecAttrAccessible as String], "Only the accessibility filter must be dropped")
    }

    func test_buildQuery_addPath_alwaysIncludesAccessibilityFilter() {
        // Add (SecItemAdd) queries always carry the accessibility so stored items keep a
        // defined protection class (D1); the opt-in flag must never affect this query.
        for matchesAnyAccessibility in [false, true] {
            var options = KeychainOptions(service: "com.forgerock.ios.test.SDKS-5451.queryshape")
            options.matchesAnyAccessibility = matchesAnyAccessibility

            for itemClass in [KeychainItemClass.genericPassword, .internetPassword, .certificate, .key] {
                let query = options.buildQuery(itemClass)
                XCTAssertEqual(query[kSecAttrAccessible as String] as? String, options.accessibility.rawValue, "buildQuery (add path) must always include the accessibility filter (flag: \(matchesAnyAccessibility), class: \(itemClass))")
            }
        }
    }


    // MARK: - SDKS-5451: flagged service behaviour against a stale-accessibility item (Task 2.3)

    func test_unflaggedService_doesNotSeeItemStoredUnderDifferentAccessibility() {
        // Guards the default: consumers that did not opt in keep today's filtered lookups
        // (KeychainManager migration probe, all other stores).
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.flagged-behaviour.key"

        // Seeder stores the item under a non-default accessibility
        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        // The class tearDown's deleteAll() is accessibility-filtered and cannot remove the
        // stale item; the seeder queries the accessibility the item was stored under.
        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "v1", "The seeded item must be readable through the seeder")

        let unflagged = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = unflagged
        XCTAssertNil(unflagged.getString(key), "An unflagged service must not see an item stored under a different accessibility")
    }

    func test_flaggedService_getStringGetDataDelete_operateOnItemStoredUnderDifferentAccessibility() {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.flagged-behaviour.key"
        let valueData = "SDKS-5451-data-value".data(using: .utf8)!

        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set(valueData, key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "SDKS-5451-data-value", "The seeded item must be readable through the seeder")

        var flaggedOptions = KeychainOptions(service: service)
        flaggedOptions.matchesAnyAccessibility = true
        let flagged = KeychainService(options: flaggedOptions)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = flagged

        XCTAssertEqual(flagged.getString(key), "SDKS-5451-data-value", "A flagged service must read an item stored under a different accessibility (AC1/AC6)")
        XCTAssertEqual(flagged.getData(key), valueData, "A flagged service must read the data of an item stored under a different accessibility (AC1/AC6)")

        XCTAssertTrue(flagged.delete(key), "A flagged service must delete an item stored under a different accessibility (AC1/AC6)")
        XCTAssertNil(seeder.getString(key), "The stale-accessibility item must be gone after the flagged delete")
    }

    func test_flaggedService_set_replacesStaleAccessibilityItem_andStoresUnderCurrentAccessibility() {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.flagged-replace.key"

        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")

        var flaggedOptions = KeychainOptions(service: service)
        flaggedOptions.matchesAnyAccessibility = true
        let flagged = KeychainService(options: flaggedOptions)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = flagged

        // Unflagged guard: before the replace the item is invisible to a default service
        let unflagged = KeychainService(service: service)
        XCTAssertNil(unflagged.getString(key), "An unflagged service must not see the item stored under a different accessibility")

        XCTAssertTrue(flagged.set("v2", key: key), "A flagged set must replace the item stored under a different accessibility")
        XCTAssertEqual(flagged.getString(key), "v2", "The replaced value must be readable through the writing service")

        // After the replace the item is stored under the flagged service's current
        // accessibility (writes still use accessibility): the filtered unflagged default
        // service can now read it, while the seeder's stale-accessibility query cannot.
        XCTAssertEqual(unflagged.getString(key), "v2", "The replaced item must be stored under the current accessibility (kSecAttrAccessibleAfterFirstUnlock)")
        XCTAssertNil(seeder.getString(key), "Exactly one item must remain after the replace, stored under the current accessibility")
    }

    func test_deleteAll_onFlaggedService_stillLeavesStaleAccessibilityItem() {
        // Documents D5/D8: deleteAll() deliberately stays accessibility-filtered even on a
        // flagged service; for non-generic classes the accessibility filter is the only
        // bound on what it deletes, so it must not become accessibility-free.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.delete-all.key"

        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")

        var flaggedOptions = KeychainOptions(service: service)
        flaggedOptions.matchesAnyAccessibility = true
        let flagged = KeychainService(options: flaggedOptions)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = flagged

        // An item under the current accessibility IS removed by deleteAll
        let plain = KeychainService(service: service)
        XCTAssertTrue(plain.set("current", key: "SDKS-5451.delete-all.current"))
        XCTAssertTrue(flagged.deleteAll(), "deleteAll must remove the items stored under the current accessibility")
        XCTAssertNil(plain.getString("SDKS-5451.delete-all.current"), "The current-accessibility item must be removed by deleteAll")

        // ...while the stale-accessibility item survives (D5/D8)
        XCTAssertEqual(seeder.getString(key), "v1", "deleteAll() must stay accessibility-filtered and leave the stale-accessibility item in place")
    }


    // MARK: - SDKS-5451: errSecDuplicateItem self-heal in set (Task 3.3, AC2)

    func test_addItem_withConflictingItemStoredUnderDifferentAccessibility_recoversAndLeavesExactlyOneItem() {
        // Task 3.3(b), AC2: both SecItemAdd call sites of set() (new-item and replace paths)
        // go through addItem(_:key:itemClass:), so a direct helper call with a pre-seeded
        // conflicting item is the deterministic structural guarantee that the two paths
        // behave identically (a natural replace-path errSecDuplicateItem needs a TOCTOU race,
        // so it is exercised probabilistically by the concurrency tests below).
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.additem.key"

        // Seeder stores the conflicting item under a non-default accessibility
        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)

        // The class tearDown's deleteAll() is accessibility-filtered and cannot remove the
        // stale item; the seeder queries the accessibility the item was stored under.
        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "v1", "The seeded item must be readable through the seeder")

        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        XCTAssertNil(kc.getString(key), "Fixture precondition: the conflicting item must be invisible to the writing service's accessibility-filtered lookup")

        // Build the add query exactly as set() builds it (no SecuredKey on the simulator)
        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "v2".data(using: .utf8)!

        // Fixture precondition: a plain add collides with the stale-accessibility item,
        // because duplicate detection ignores kSecAttrAccessible
        XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecDuplicateItem, "Fixture precondition: SecItemAdd must return errSecDuplicateItem against the conflicting item")

        // When: the add goes through the shared helper (as both set() paths do)
        let status = kc.addItem(query, key: key, itemClass: .genericPassword)

        // Then: the helper recovers exactly once and exactly one item remains
        XCTAssertEqual(status, errSecSuccess, "addItem must recover from errSecDuplicateItem by removing the conflicting item and retrying once")
        XCTAssertEqual(kc.getString(key), "v2", "The recovered item must hold the new value")
        XCTAssertEqual(kc.allItems()?.count, 1, "Exactly one item must remain after the recovery")
        XCTAssertNil(seeder.getString(key), "The conflicting stale-accessibility item must be gone")
    }

    func test_set_recoveryOnAccessGroupService_preservesBystanderItemInDefaultGroup() {
        // Task 3.3(c), AC2: the recovery delete is buildQuery(_:includeAccessibility: false)
        // + account, so kSecAttrAccessGroup is preserved and the delete can never cross the
        // group boundary. A bystander item with the same service+account in the default group
        // must survive a recovery that removes a stale-accessibility item in group G.
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }

        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.accessgroup.key"

        // Seeder stores the conflicting item in group G (Team-ID-prefixed by the options init)
        // under a non-default accessibility
        var seederOptions = KeychainOptions(service: service, accessGroup: accessGroup)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)
        XCTAssertNotNil(seeder.options.accessGroup, "The group-G seeder must carry the (team-prefixed) access group")

        // Bystander with the same service+account in the DEFAULT access group (accessGroup unset)
        let bystanderService = KeychainService(service: service)
        XCTAssertNil(bystanderService.options.accessGroup, "The bystander service must have no access group")

        // The class tearDown's deleteAll() on the G service cannot match the no-group
        // bystander, and the seeder's filtered delete cannot match a replaced item; both are
        // deleted explicitly here.
        self.addTeardownBlock {
            _ = bystanderService.delete(key)
        }
        self.addTeardownBlock {
            _ = seeder.delete(key)
        }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the group-G item under a non-default accessibility must succeed")
        XCTAssertTrue(bystanderService.set("bystander", key: key), "Seeding the default-group bystander must succeed")

        let groupService = KeychainService(service: service, accessGroup: accessGroup)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = groupService

        // Fixture preconditions: the group-G service sees neither the stale item (different
        // accessibility) nor the bystander (different access group)
        XCTAssertEqual(seeder.getString(key), "v1", "The stale-accessibility group-G item must be readable through the seeder")
        XCTAssertNil(groupService.getString(key), "Fixture precondition: the group-G service's filtered lookup must see neither conflicting item")
        XCTAssertEqual(bystanderService.getString(key), "bystander", "The default-group bystander must be readable through its own service")

        // When: the group-G service writes over the stale item (the add returns
        // errSecDuplicateItem and the self-heal removes the conflicting item)
        XCTAssertTrue(groupService.set("v2", key: key), "set via the group-G service must recover from errSecDuplicateItem")

        // Then: the recovery preserved the access group - the group-G item was replaced...
        XCTAssertEqual(groupService.getString(key), "v2", "The replaced item must be readable through the group-G service")
        XCTAssertNil(seeder.getString(key), "The stale group-G item must be gone after the recovery")

        // ...and the bystander in the default group survived. The bystander's own group-free
        // read is ambiguous (it matches items in every group the app can access, including the
        // new group-G item), so survival is verified by an attribute-level inventory query that
        // pins each surviving item to its access group.
        var inventoryQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var inventoryResult: AnyObject?
        let inventoryStatus = SecItemCopyMatching(inventoryQuery as CFDictionary, &inventoryResult)
        XCTAssertEqual(inventoryStatus, errSecSuccess, "The accessibility-free service+account inventory query must find the surviving items")
        let inventory = inventoryResult as? [[String: Any]] ?? []
        let groupGItems = inventory.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix(accessGroup) == true }
        let defaultGroupItems = inventory.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix("com.forgerock.ios.FRTestHost") == true }
        XCTAssertEqual(groupGItems.count, 1, "Exactly one item must remain in the config access group")
        XCTAssertEqual(defaultGroupItems.count, 1, "The default-group bystander must survive the group-G recovery delete (kSecAttrAccessGroup preserved; recovery delete must not cross the group boundary)")
        XCTAssertEqual(defaultGroupItems.first?[kSecValueData as String] as? Data, "bystander".data(using: .utf8), "The surviving default-group item must be the untouched bystander value")
    }

    func test_set_recoveryOnNoGroupService_deletesAcrossGroups_byPreExistingDesign() {
        // Mirror of test_set_recoveryOnAccessGroupService_preservesBystanderItemInDefaultGroup,
        // pinning the opposite, PRE-EXISTING behaviour of a no-group (accessGroup == nil)
        // KeychainService: with no kSecAttrAccessGroup in the query, SecItemDelete matches
        // across every group the app belongs to (accessibility-filtered only) — the replace
        // path of set() has always done this (SDKS-5451 plan Risk 6), and the recovery delete
        // keeps exactly the same reach, only extending it to items under OTHER accessibilities.
        //
        // This test pins that documented reach so a future default-group-scoping change is a
        // deliberate, visible decision rather than a silent behaviour shift. A no-group add
        // lands in the default group (SecItemAdd duplicate detection IS access-group-scoped,
        // so the item that triggers recovery is always in the default group); the group-G item
        // below is the same class+service+account in another group the app can access — the
        // only scenario in which the unscoped delete reaches beyond the default group.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.nogroup.reach.key"

        // A same class+service+account item in the config access group under a different
        // accessibility. The app belongs to both groups, so an unscoped delete can match it.
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }
        var groupSeederOptions = KeychainOptions(service: service, accessGroup: accessGroup)
        groupSeederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let groupSeeder = KeychainService(options: groupSeederOptions)
        self.addTeardownBlock {
            _ = groupSeeder.delete(key)
        }

        XCTAssertTrue(groupSeeder.set("group-g-item", key: key), "Seeding the group-G same-service item must succeed")
        XCTAssertEqual(groupSeeder.getString(key), "group-g-item", "The group-G item must be readable through its own (group-scoped, matching-accessibility) service")

        // The no-group conflicting item in the DEFAULT group under a different accessibility.
        var seederOptions = KeychainOptions(service: service)
        seederOptions.accessibility = .whenUnlockedThisDeviceOnly
        let seeder = KeychainService(options: seederOptions)
        self.addTeardownBlock {
            _ = seeder.delete(key)
        }
        XCTAssertTrue(seeder.set("stale", key: key), "Seeding the default-group stale item must succeed")

        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        XCTAssertNil(kc.getString(key), "Fixture precondition: the stale item must be invisible to the no-group service's accessibility-filtered lookup")

        // When: the no-group service writes over the stale item; the add returns
        // errSecDuplicateItem and the self-heal fires with an unscoped conflict query.
        XCTAssertTrue(kc.set("v2", key: key), "set via the no-group service must recover from errSecDuplicateItem")

        // Then: the intended target was replaced...
        XCTAssertEqual(kc.getString(key), "v2", "The recovered item must hold the new value")

        // ...and because options.accessGroup is nil, the recovery delete ALSO removed the
        // same class+service+account item in group G. This is the pre-existing reach of
        // every no-group SecItemDelete in this SDK (replace path included) — pinned here
        // as documented behaviour, not flagged as a defect (plan Risk 6).
        var inventoryQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var inventoryResult: AnyObject?
        let inventoryStatus = SecItemCopyMatching(inventoryQuery as CFDictionary, &inventoryResult)
        XCTAssertEqual(inventoryStatus, errSecSuccess, "The accessibility-free service+account inventory query must succeed")
        let inventory = inventoryResult as? [[String: Any]] ?? []
        XCTAssertEqual(inventory.count, 1, "The no-group recovery delete must have removed BOTH same-service items (default-group stale item AND group-G item) — the pre-existing group-unscoped reach of a nil-accessGroup delete")
        let groupGItems = inventory.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix(accessGroup) == true }
        XCTAssertTrue(groupGItems.isEmpty, "The group-G same-service item must be gone: the recovery delete, like the replace-path delete before it, is not scoped to the default group when options.accessGroup is nil")
        XCTAssertEqual(kc.getString(key), "v2", "Exactly the recovered default-group item remains")
    }


    // MARK: - SDKS-5451: concurrent writers on one key (Task 3.4, AC2/AC5)

    func test_set_concurrentWritersOnSameNewKey_bothSucceed() {
        // AC5: two concurrent set() calls on the same new key must both succeed. Both writers
        // pass the existence check (TOCTOU), one SecItemAdd returns errSecDuplicateItem, and
        // the self-heal deletes the winner's item and re-adds (last-writer-wins, the same
        // semantics as the replace path). Probabilistic by nature; the deterministic tests
        // above are the primary guarantee.
        let rounds = 50
        let service = "com.forgerock.ios.test.SDKS-5451.concurrent.\(UUID().uuidString)"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        for round in 0..<rounds {
            // Fresh key per round: both writers take the new-item path
            let key = "SDKS-5451.concurrent.new.\(round)"
            let valueA = "round-\(round)-writer-A"
            let valueB = "round-\(round)-writer-B"

            var results: [Bool] = []
            let lock = NSLock()

            DispatchQueue.concurrentPerform(iterations: 2) { iteration in
                let writer = KeychainService(service: service)
                let success = writer.set(iteration == 0 ? valueA : valueB, key: key)
                lock.lock()
                results.append(success)
                lock.unlock()
            }

            // Assertions only after DispatchQueue.concurrentPerform has returned
            XCTAssertEqual(results.count, 2, "Both writers must report a result (round \(round))")
            XCTAssertTrue(results.allSatisfy { $0 }, "Both concurrent writers must succeed (round \(round); results: \(results))")
            let finalValue = kc.getString(key)
            XCTAssertTrue(finalValue == valueA || finalValue == valueB, "The final value must be one of the two written values (round \(round); was \(finalValue ?? "nil"))")
        }
    }

    func test_set_concurrentWritersOnExistingKey_bothSucceed() {
        // AC5, replace-path race: both writers see the pre-seeded item, both delete it, and
        // one SecItemAdd returns errSecDuplicateItem, which the self-heal recovers. A natural
        // replace-path collision needs this TOCTOU race, so this coverage is probabilistic;
        // the direct-helper test above is the deterministic replace-path guarantee.
        let rounds = 50
        let service = "com.forgerock.ios.test.SDKS-5451.concurrent.\(UUID().uuidString)"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        for round in 0..<rounds {
            let key = "SDKS-5451.concurrent.existing.\(round)"
            // Pre-seed the key so both writers take the replace path
            XCTAssertTrue(kc.set("seed", key: key), "Seeding the existing key must succeed (round \(round))")

            let valueA = "round-\(round)-writer-A"
            let valueB = "round-\(round)-writer-B"

            var results: [Bool] = []
            let lock = NSLock()

            DispatchQueue.concurrentPerform(iterations: 2) { iteration in
                let writer = KeychainService(service: service)
                let success = writer.set(iteration == 0 ? valueA : valueB, key: key)
                lock.lock()
                results.append(success)
                lock.unlock()
            }

            // Assertions only after DispatchQueue.concurrentPerform has returned
            XCTAssertEqual(results.count, 2, "Both writers must report a result (round \(round))")
            XCTAssertTrue(results.allSatisfy { $0 }, "Both concurrent writers must succeed (round \(round); results: \(results))")
            let finalValue = kc.getString(key)
            XCTAssertTrue(finalValue == valueA || finalValue == valueB, "The final value must be one of the two written values (round \(round); was \(finalValue ?? "nil"))")
        }
    }

}
