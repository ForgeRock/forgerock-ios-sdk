//
//  KeychainServiceTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
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
        XCTAssertTrue(KeychainService.validateAccessGroup(service: "com.forgerofck.ios", accessGroup: "JV6EC9KSN3.\(accessGroup)"))
        
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
}
