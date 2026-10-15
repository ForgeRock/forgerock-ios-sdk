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

        // Raw Security.framework probe (no SDK code): kSecAttrAccessible acts as a lookup
        // filter (SecItemCopyMatching returns errSecItemNotFound) while SecItemAdd still
        // detects duplicates on class+service+account(+accessGroup) only
        // (errSecDuplicateItem). Tripwire for Apple changing the semantics the Keychain
        // fixes rely on.
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


    func test_platform_secItemUpdate_changesAccessibilityOfItemMatchedWithoutAccessibility() {
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }

        guard let appleTeamId = KeychainService.getAppleTeamId() else {
            XCTFail("Failed to retrieve Apple Team ID")
            return
        }

        // Raw Security.framework probe (no SDK code): the update-based recovery in
        // KeychainService.addItem relies on SecItemUpdate matching an item without the
        // accessibility filter and rewriting kSecAttrAccessible together with the value.
        self.runSecItemUpdateAccessibilityProbe(service: "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)", accessGroup: nil)
        self.runSecItemUpdateAccessibilityProbe(service: "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)", accessGroup: appleTeamId + "." + accessGroup)
    }

    private func runSecItemUpdateAccessibilityProbe(service: String, accessGroup: String?) {
        let account = "SDKS-5451.update-probe.account"
        let accessibilityA = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        let accessibilityB = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        let groupDescription = accessGroup ?? "nil"

        var identityQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup = accessGroup {
            identityQuery[kSecAttrAccessGroup as String] = accessGroup
        }
        defer {
            SecItemDelete(identityQuery as CFDictionary)
        }

        var addQuery = identityQuery
        addQuery[kSecValueData as String] = "old".data(using: .utf8)!
        addQuery[kSecAttrAccessible as String] = accessibilityA
        XCTAssertEqual(SecItemAdd(addQuery as CFDictionary, nil), errSecSuccess, "Seeding under accessibility A must succeed (accessGroup: \(groupDescription))")

        let attributes: [String: Any] = [
            kSecValueData as String: "new".data(using: .utf8)!,
            kSecAttrAccessible as String: accessibilityB
        ]
        XCTAssertEqual(SecItemUpdate(identityQuery as CFDictionary, attributes as CFDictionary), errSecSuccess, "SecItemUpdate without an accessibility filter must match the item and rewrite its accessibility (accessGroup: \(groupDescription))")

        var readQuery = identityQuery
        readQuery[kSecReturnData as String] = true
        readQuery[kSecAttrAccessible as String] = accessibilityB
        var result: AnyObject?
        XCTAssertEqual(SecItemCopyMatching(readQuery as CFDictionary, &result), errSecSuccess, "The updated item must be found under the new accessibility (accessGroup: \(groupDescription))")
        XCTAssertEqual(result as? Data, "new".data(using: .utf8), "The updated item must hold the new value (accessGroup: \(groupDescription))")

        readQuery[kSecAttrAccessible as String] = accessibilityA
        XCTAssertEqual(SecItemCopyMatching(readQuery as CFDictionary, nil), errSecItemNotFound, "The updated item must no longer be found under the old accessibility (accessGroup: \(groupDescription))")
    }




    // MARK: - SDKS-5451: helpers

    /// Stores items under a non-default accessibility, so they are invisible to a default-accessibility service
    private func makeStaleSeeder(service: String, accessGroup: String? = nil) -> KeychainService {
        var options: KeychainOptions
        if let accessGroup = accessGroup {
            options = KeychainOptions(service: service, accessGroup: accessGroup)
        } else {
            options = KeychainOptions(service: service)
        }
        options.accessibility = .whenUnlockedThisDeviceOnly
        return KeychainService(options: options)
    }

    /// Accessibility-free, group-unscoped inventory (attributes and data) of the generic-password items for service+key
    private func inventory(service: String, key: String) -> [[String: Any]] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound, "Inventory query returned unexpected status \(status)")
        return result as? [[String: Any]] ?? []
    }

    /// Removes every generic-password item of the service regardless of accessibility and access group
    private func removeAllItems(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func value(of item: [String: Any]) -> String? {
        return (item[kSecValueData as String] as? Data).flatMap { String(data: $0, encoding: .utf8) }
    }


    // MARK: - SDKS-5451: replace over a stale-accessibility item

    func test_set_overItemStoredUnderDifferentAccessibility_succeedsAndReplacesValue() {
        // The existence check and the replace-path delete are accessibility-filtered
        // (errSecItemNotFound) while SecItemAdd still detects the duplicate
        // (errSecDuplicateItem); addItem(_:key:itemClass:) recovers from the duplicate.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.replace.key"

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "v1", "The seeded item must be readable through the seeder")

        // Default service (kSecAttrAccessibleAfterFirstUnlock) writes over the item
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        XCTAssertTrue(kc.set("v2", key: key), "set must replace the item stored under a different accessibility")
        XCTAssertEqual(kc.getString(key), "v2", "The replaced value must be readable through the writing service")
        XCTAssertNil(seeder.getString(key), "The item must now be stored under the writing service's accessibility")
        XCTAssertEqual(self.inventory(service: service, key: key).count, 1, "Exactly one item must remain after the replace")
    }


    // MARK: - SDKS-5451: accessibility-free lookup query shape

    func test_buildLookupQuery_defaultOptions_keepAccessibilityFilterForAllClasses() {
        // With the default options (matchesAnyAccessibility == false) lookups stay
        // accessibility-filtered for every item class.
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
        // so dropping it would make lookups match unrelated items
        for itemClass in [KeychainItemClass.internetPassword, .certificate, .key, .securedKey, .identity] {
            let query = options.buildLookupQuery(itemClass)
            XCTAssertEqual(query[kSecAttrAccessible as String] as? String, options.accessibility.rawValue, "Non-generic classes must keep the accessibility filter even when flagged (class: \(itemClass))")
        }
    }

    func test_buildLookupQuery_matchesAnyAccessibility_keepsClassServiceAccessGroupAndSynchronizable() {
        // Relaxing only the accessibility filter must not drop any other identity attribute
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
        // defined protection class; the opt-in flag must never affect this query.
        for matchesAnyAccessibility in [false, true] {
            var options = KeychainOptions(service: "com.forgerock.ios.test.SDKS-5451.queryshape")
            options.matchesAnyAccessibility = matchesAnyAccessibility

            for itemClass in [KeychainItemClass.genericPassword, .internetPassword, .certificate, .key] {
                let query = options.buildQuery(itemClass)
                XCTAssertEqual(query[kSecAttrAccessible as String] as? String, options.accessibility.rawValue, "buildQuery (add path) must always include the accessibility filter (flag: \(matchesAnyAccessibility), class: \(itemClass))")
            }
        }
    }


    // MARK: - SDKS-5451: flagged service behaviour against a stale-accessibility item

    func test_unflaggedService_doesNotSeeItemStoredUnderDifferentAccessibility() {
        // Consumers that did not opt in keep filtered lookups
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.flagged-behaviour.key"

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

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

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

        XCTAssertTrue(seeder.set(valueData, key: key), "Seeding the item under a non-default accessibility must succeed")
        XCTAssertEqual(seeder.getString(key), "SDKS-5451-data-value", "The seeded item must be readable through the seeder")

        var flaggedOptions = KeychainOptions(service: service)
        flaggedOptions.matchesAnyAccessibility = true
        let flagged = KeychainService(options: flaggedOptions)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = flagged

        XCTAssertEqual(flagged.getString(key), "SDKS-5451-data-value", "A flagged service must read an item stored under a different accessibility")
        XCTAssertEqual(flagged.getData(key), valueData, "A flagged service must read the data of an item stored under a different accessibility")

        XCTAssertTrue(flagged.delete(key), "A flagged service must delete an item stored under a different accessibility")
        XCTAssertNil(seeder.getString(key), "The stale-accessibility item must be gone after the flagged delete")
    }

    func test_flaggedService_set_replacesStaleAccessibilityItem_andStoresUnderCurrentAccessibility() {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.flagged-replace.key"

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the item under a non-default accessibility must succeed")

        var flaggedOptions = KeychainOptions(service: service)
        flaggedOptions.matchesAnyAccessibility = true
        let flagged = KeychainService(options: flaggedOptions)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = flagged

        // Before the replace the item is invisible to a default service
        let unflagged = KeychainService(service: service)
        XCTAssertNil(unflagged.getString(key), "An unflagged service must not see the item stored under a different accessibility")

        XCTAssertTrue(flagged.set("v2", key: key), "A flagged set must replace the item stored under a different accessibility")
        XCTAssertEqual(flagged.getString(key), "v2", "The replaced value must be readable through the writing service")

        // Writes still use the options' accessibility: the filtered default service can now
        // read the item, while the seeder's stale-accessibility query cannot.
        XCTAssertEqual(unflagged.getString(key), "v2", "The replaced item must be stored under the current accessibility (kSecAttrAccessibleAfterFirstUnlock)")
        XCTAssertNil(seeder.getString(key), "Exactly one item must remain after the replace, stored under the current accessibility")
        XCTAssertEqual(self.inventory(service: service, key: key).count, 1, "Exactly one item must remain after the replace")
    }

    func test_deleteAll_onFlaggedService_stillLeavesStaleAccessibilityItem() {
        // deleteAll() stays accessibility-filtered even on a flagged service; for non-generic
        // classes the accessibility filter is the only bound on what it deletes.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.delete-all.key"

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

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

        // ...while the stale-accessibility item survives
        XCTAssertEqual(seeder.getString(key), "v1", "deleteAll() must stay accessibility-filtered and leave the stale-accessibility item in place")
    }


    // MARK: - SDKS-5451: errSecDuplicateItem recovery in addItem

    func test_addItem_withConflictingItemStoredUnderDifferentAccessibility_updatesInPlaceAndLeavesExactlyOneItem() {
        // Both SecItemAdd call sites of set() (new-item and replace paths) go through
        // addItem(_:key:itemClass:), so a direct call with a pre-seeded conflicting item is the
        // deterministic check for both; a natural replace-path duplicate needs a TOCTOU race and
        // is exercised by the concurrency tests below.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.additem.key"

        let seeder = self.makeStaleSeeder(service: service)
        self.addTeardownBlock { self.removeAllItems(service: service) }

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

        // A plain add collides with the stale-accessibility item, because duplicate
        // detection ignores kSecAttrAccessible
        XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecDuplicateItem, "Fixture precondition: SecItemAdd must return errSecDuplicateItem against the conflicting item")

        let status = kc.addItem(query, key: key, itemClass: .genericPassword)

        XCTAssertEqual(status, errSecSuccess, "addItem must recover from errSecDuplicateItem by updating the conflicting item")
        XCTAssertEqual(kc.getString(key), "v2", "The recovered item must hold the new value and the writing service's accessibility")
        XCTAssertNil(seeder.getString(key), "The item must no longer be stored under the stale accessibility")
        let items = self.inventory(service: service, key: key)
        XCTAssertEqual(items.count, 1, "Exactly one item must remain after the recovery")
        XCTAssertEqual(items.first?[kSecAttrAccessible as String] as? String, kc.options.accessibility.rawValue, "The recovered item must carry the add query's accessibility")
    }

    func test_addItem_whenRecoveryUpdateFindsNothing_retriesAddOnceAndSucceeds() {
        // The conflicting item vanished between the failed add and the update: the original add
        // is attempted exactly once more and its status is returned.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.update-notfound.key"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "new".data(using: .utf8)!

        var addStatuses: [OSStatus] = [errSecDuplicateItem, noErr]
        var addCalls = 0
        var updateCalls = 0
        let status = kc.addItem(query, key: key, itemClass: .genericPassword, add: { _ in
            addCalls += 1
            return addStatuses.removeFirst()
        }, update: { _, _ in
            updateCalls += 1
            return errSecItemNotFound
        })

        XCTAssertEqual(status, noErr, "The retried add's success must be returned")
        XCTAssertEqual(addCalls, 2, "The original add must be retried exactly once")
        XCTAssertEqual(updateCalls, 1, "The conflicting item must be updated exactly once")
    }

    func test_addItem_whenRecoveryUpdateFindsNothing_andRetryAlsoFails_returnsRetryStatusWithoutThirdAdd() {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.update-notfound-retry-fails.key"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "new".data(using: .utf8)!

        var addStatuses: [OSStatus] = [errSecDuplicateItem, errSecInteractionNotAllowed, errSecDuplicateItem]
        var addCalls = 0
        var updateCalls = 0
        let status = kc.addItem(query, key: key, itemClass: .genericPassword, add: { _ in
            addCalls += 1
            return addStatuses.removeFirst()
        }, update: { _, _ in
            updateCalls += 1
            return errSecItemNotFound
        })

        XCTAssertEqual(status, errSecInteractionNotAllowed, "The failed retry's status must be returned")
        XCTAssertEqual(addCalls, 2, "The recovery must be bounded: no third add")
        XCTAssertEqual(updateCalls, 1, "The conflicting item must be updated exactly once")
    }

    func test_addItem_whenRecoveryUpdateFailsWithInteractionNotAllowed_returnsDuplicateAndLeavesOldItemIntact() {
        self.assertFailedRecoveryLeavesOldItemIntact(updateStatus: errSecInteractionNotAllowed)
    }

    func test_addItem_whenRecoveryUpdateFailsWithAuthFailed_returnsDuplicateAndLeavesOldItemIntact() {
        self.assertFailedRecoveryLeavesOldItemIntact(updateStatus: errSecAuthFailed)
    }

    /// Scripts a recovery `SecItemUpdate` failure (neither success nor errSecItemNotFound) against a real stale-accessibility item
    private func assertFailedRecoveryLeavesOldItemIntact(updateStatus: OSStatus, file: StaticString = #filePath, line: UInt = #line) {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.update-failure.key"
        self.addTeardownBlock { self.removeAllItems(service: service) }

        let seeder = self.makeStaleSeeder(service: service)
        XCTAssertTrue(seeder.set("old", key: key), "Seeding the item under a non-default accessibility must succeed", file: file, line: line)

        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "new".data(using: .utf8)!

        var addCalls = 0
        var updateCalls = 0
        let status = kc.addItem(query, key: key, itemClass: .genericPassword, add: { addQuery in
            addCalls += 1
            return SecItemAdd(addQuery, nil)
        }, update: { _, _ in
            updateCalls += 1
            return updateStatus
        })

        XCTAssertEqual(status, errSecDuplicateItem, "A failed recovery must return the original errSecDuplicateItem (update status: \(updateStatus))", file: file, line: line)
        XCTAssertEqual(addCalls, 1, "A failed recovery must not retry the add", file: file, line: line)
        XCTAssertEqual(updateCalls, 1, "The conflicting item must be updated exactly once", file: file, line: line)
        XCTAssertEqual(seeder.getString(key), "old", "The old item's value must be unchanged and still stored under its original accessibility", file: file, line: line)
        let items = self.inventory(service: service, key: key)
        XCTAssertEqual(items.count, 1, "Exactly the old item must remain", file: file, line: line)
        XCTAssertEqual(self.value(of: items.first ?? [:]), "old", "The old item's value must be unchanged", file: file, line: line)
        XCTAssertEqual(items.first?[kSecAttrAccessible as String] as? String, KeychainAccessibility.whenUnlockedThisDeviceOnly.rawValue, "The old item's accessibility must be unchanged", file: file, line: line)
    }

    func test_addItem_calledTwiceOverStaleAccessibilityItem_bothSucceedLeavingOneItem() {
        // Deterministic double recovery: the second add collides with the item the first
        // recovery just updated, and recovers again without deleting anything.
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.double-recovery.key"
        self.addTeardownBlock { self.removeAllItems(service: service) }

        let seeder = self.makeStaleSeeder(service: service)
        XCTAssertTrue(seeder.set("seed", key: key), "Seeding the item under a non-default accessibility must succeed")

        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "v2".data(using: .utf8)!

        XCTAssertEqual(kc.addItem(query, key: key, itemClass: .genericPassword), noErr, "The first recovery must succeed")
        XCTAssertEqual(kc.addItem(query, key: key, itemClass: .genericPassword), noErr, "The second recovery over the already-updated item must succeed")

        let items = self.inventory(service: service, key: key)
        XCTAssertEqual(items.count, 1, "Exactly one item must remain")
        XCTAssertEqual(self.value(of: items.first ?? [:]), "v2")
        XCTAssertEqual(items.first?[kSecAttrAccessible as String] as? String, kc.options.accessibility.rawValue, "The surviving item must carry the add query's accessibility")
    }

    func test_addItem_withoutConflict_addsItemWithoutRecovery() {
        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.no-conflict.key"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc

        var query = kc.options.buildQuery(.genericPassword)
        query[kSecAttrAccount as String] = key
        query[kSecValueData as String] = "v1".data(using: .utf8)!

        XCTAssertEqual(kc.addItem(query, key: key, itemClass: .genericPassword), errSecSuccess)
        XCTAssertEqual(kc.getString(key), "v1")
    }

    func test_set_recoveryOnAccessGroupService_preservesBystanderItemInDefaultGroup() {
        // The recovery update is buildQuery(_:includeAccessibility: false) + account, so
        // kSecAttrAccessGroup is preserved and the update never crosses the group boundary: a
        // bystander with the same service+account in the default group is untouched when a
        // stale-accessibility item in group G is recovered.
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }

        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.accessgroup.key"

        // Seeder stores the conflicting item in group G (Team-ID-prefixed by the options init)
        let seeder = self.makeStaleSeeder(service: service, accessGroup: accessGroup)
        XCTAssertNotNil(seeder.options.accessGroup, "The group-G seeder must carry the (team-prefixed) access group")

        // Bystander with the same service+account in the DEFAULT access group (accessGroup unset)
        let bystanderService = KeychainService(service: service)
        XCTAssertNil(bystanderService.options.accessGroup, "The bystander service must have no access group")
        self.addTeardownBlock { self.removeAllItems(service: service) }

        XCTAssertTrue(seeder.set("v1", key: key), "Seeding the group-G item under a non-default accessibility must succeed")
        XCTAssertTrue(bystanderService.set("bystander", key: key), "Seeding the default-group bystander must succeed")

        let groupService = KeychainService(service: service, accessGroup: accessGroup)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = groupService

        // The group-G service sees neither the stale item (different accessibility) nor the
        // bystander (different access group)
        XCTAssertEqual(seeder.getString(key), "v1", "The stale-accessibility group-G item must be readable through the seeder")
        XCTAssertNil(groupService.getString(key), "Fixture precondition: the group-G service's filtered lookup must see neither conflicting item")
        XCTAssertEqual(bystanderService.getString(key), "bystander", "The default-group bystander must be readable through its own service")

        XCTAssertTrue(groupService.set("v2", key: key), "set via the group-G service must recover from errSecDuplicateItem")

        XCTAssertEqual(groupService.getString(key), "v2", "The recovered item must be readable through the group-G service")
        XCTAssertNil(seeder.getString(key), "The group-G item must no longer be stored under the stale accessibility")

        // The bystander's own group-free read is ambiguous (it matches items in every group
        // the app can access), so survival is verified by an inventory pinned to access group.
        let inventory = self.inventory(service: service, key: key)
        let groupGItems = inventory.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix(accessGroup) == true }
        // The default group's name comes from the test host's keychain-access-groups
        // entitlement rather than its bundle identifier, so the bystander is identified
        // negatively: an item outside the config access group.
        let defaultGroupItems = inventory.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix(accessGroup) != true }
        XCTAssertEqual(groupGItems.count, 1, "Exactly one item must remain in the config access group")
        XCTAssertEqual(defaultGroupItems.count, 1, "The default-group bystander must survive the group-G recovery (kSecAttrAccessGroup preserved)")
        XCTAssertEqual(self.value(of: defaultGroupItems[0]), "bystander", "The surviving default-group item must be the untouched bystander value")
        XCTAssertEqual(defaultGroupItems[0][kSecAttrAccessible as String] as? String, KeychainAccessibility.afterFirstUnlock.rawValue, "The bystander's accessibility must be unchanged")
    }

    func test_set_recoveryOnNoGroupService_overwritesAcrossGroups_byPreExistingDesign() {
        // With options.accessGroup == nil the recovery update carries no kSecAttrAccessGroup, so
        // it matches across every group the app belongs to, the same group-unscoped reach as the
        // replace-path delete in set(). A same class+service+account item in another accessible
        // group is overwritten (value and accessibility), not deleted. This is pre-existing
        // reach of a no-group service, pinned here so changing it is a deliberate decision.
        guard let accessGroup = self.config.keychainAccessGroup else {
            XCTFail("Failed to retrieve Access Group Identifier from Config object")
            return
        }

        let service = "com.forgerock.ios.test.SDKS-5451.\(UUID().uuidString)"
        let key = "SDKS-5451.nogroup.reach.key"
        self.addTeardownBlock { self.removeAllItems(service: service) }

        // The conflicting item in the DEFAULT group under a different accessibility. It is seeded
        // first: the no-group seeder's replace path is group-unscoped and would delete a
        // group-G item seeded before it.
        let seeder = self.makeStaleSeeder(service: service)
        XCTAssertTrue(seeder.set("stale", key: key), "Seeding the default-group stale item must succeed")

        // A same class+service+account item in the config access group under a different accessibility
        let groupSeeder = self.makeStaleSeeder(service: service, accessGroup: accessGroup)
        XCTAssertTrue(groupSeeder.set("group-g-item", key: key), "Seeding the group-G same-service item must succeed")
        XCTAssertEqual(groupSeeder.getString(key), "group-g-item", "The group-G item must be readable through its own (group-scoped, matching-accessibility) service")

        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        XCTAssertNil(kc.getString(key), "Fixture precondition: the stale item must be invisible to the no-group service's accessibility-filtered lookup")
        XCTAssertEqual(self.inventory(service: service, key: key).count, 2, "Fixture precondition: both same-service items must exist")

        XCTAssertTrue(kc.set("v2", key: key), "set via the no-group service must recover from errSecDuplicateItem")

        let items = self.inventory(service: service, key: key)
        XCTAssertEqual(items.count, 2, "The unscoped recovery update must not delete any item")
        XCTAssertTrue(items.allSatisfy { self.value(of: $0) == "v2" }, "The unscoped recovery update must overwrite the value of every matching item, including the one in the other group")
        XCTAssertTrue(items.allSatisfy { ($0[kSecAttrAccessible as String] as? String) == kc.options.accessibility.rawValue }, "The unscoped recovery update must also rewrite the accessibility of every matching item")
        XCTAssertEqual(items.filter { ($0[kSecAttrAccessGroup as String] as? String)?.hasSuffix(accessGroup) == true }.count, 1, "The group-G item must still exist in its own group")
    }


    // MARK: - SDKS-5451: accessibility name mapping for the recovery diagnostic

    func test_accessibilityName_mapsKnownConstantsAndFallsBackToRawCode() {
        let all: [KeychainAccessibility] = [.afterFirstUnlock, .afterFirstUnlockThisDeviceOnly, .whenUnlocked, .whenUnlockedThisDeviceOnly, .whenPasscodeSetThisDeviceOnly, .alwaysThisDeviceOnly]
        for accessibility in all {
            XCTAssertEqual(KeychainService.accessibilityName(for: accessibility.rawValue), accessibility.description)
        }
        XCTAssertEqual(KeychainService.accessibilityName(for: "cku"), "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly")
        // Deprecated kSecAttrAccessibleAlways has no KeychainAccessibility case
        XCTAssertEqual(KeychainService.accessibilityName(for: "dk"), "dk")
        XCTAssertEqual(KeychainService.accessibilityName(for: "unmapped"), "unmapped")
    }


    // MARK: - SDKS-5451: concurrent writers on one key

    func test_set_concurrentWritersOnSameNewKey_bothSucceed() {
        // Probabilistic: two concurrent set() calls on a new key may both pass the existence
        // check, in which case one add collides and recovers. The interleaving is not
        // controlled, so any given run may never hit it; the deterministic addItem tests above
        // are the guarantee, this is a smoke test for the end state.
        let rounds = 50
        let service = "com.forgerock.ios.test.SDKS-5451.concurrent.\(UUID().uuidString)"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        self.addTeardownBlock { self.removeAllItems(service: service) }

        for round in 0..<rounds {
            let key = "SDKS-5451.concurrent.new.\(round)"
            self.runConcurrentWriters(service: service, key: key, round: round)
        }
    }

    func test_set_concurrentWritersOnExistingKey_bothSucceed() {
        // Probabilistic: both writers may see the pre-seeded item and delete it, after which
        // one add can collide. The interleaving is not controlled; the deterministic addItem
        // tests above are the guarantee, this is a smoke test for the end state.
        let rounds = 50
        let service = "com.forgerock.ios.test.SDKS-5451.concurrent.\(UUID().uuidString)"
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        self.addTeardownBlock { self.removeAllItems(service: service) }

        for round in 0..<rounds {
            let key = "SDKS-5451.concurrent.existing.\(round)"
            XCTAssertTrue(kc.set("seed", key: key), "Seeding the existing key must succeed (round \(round))")
            self.runConcurrentWriters(service: service, key: key, round: round)
        }
    }

    func test_set_concurrentWritersOnKeyStoredUnderDifferentAccessibility_bothSucceedLeavingOneItem() {
        // Each round's key is seeded under a non-default accessibility, so both unflagged
        // writers miss it in the existence check and their adds collide with it. Probabilistic:
        // whether both recoveries overlap in time is not controlled, so this only checks the
        // end state (both succeed, one item, current accessibility); the deterministic addItem
        // tests above are the guarantee.
        let rounds = 50
        let service = "com.forgerock.ios.test.SDKS-5451.concurrent.\(UUID().uuidString)"
        let seeder = self.makeStaleSeeder(service: service)
        let kc = KeychainService(service: service)
        // Assign instance variable of KeychainService to delete all items upon tear down
        self.kc = kc
        self.addTeardownBlock { self.removeAllItems(service: service) }

        for round in 0..<rounds {
            let key = "SDKS-5451.concurrent.stale.\(round)"
            XCTAssertTrue(seeder.set("seed", key: key), "Seeding the stale-accessibility key must succeed (round \(round))")
            self.runConcurrentWriters(service: service, key: key, round: round)
            let items = self.inventory(service: service, key: key)
            XCTAssertEqual(items.first?[kSecAttrAccessible as String] as? String, kc.options.accessibility.rawValue, "The surviving item must be stored under the writers' accessibility (round \(round))")
        }
    }

    /// Runs two concurrent unflagged writers on the key and asserts both succeed, exactly one item remains, and its value is one of the two written values
    private func runConcurrentWriters(service: String, key: String, round: Int) {
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
        let items = self.inventory(service: service, key: key)
        XCTAssertEqual(items.count, 1, "Exactly one item must remain for the key (round \(round))")
        let finalValue = items.first.flatMap { self.value(of: $0) }
        XCTAssertTrue(finalValue == valueA || finalValue == valueB, "The final value must be one of the two written values (round \(round); was \(finalValue ?? "nil"))")
    }

}
