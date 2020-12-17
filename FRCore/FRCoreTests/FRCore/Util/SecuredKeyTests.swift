// 
//  SecuredKeyTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class SecuredKeyTests: FRBaseTestCase {
    
    let applicationTag1 = "application_tag_one"
    let applicationTag2 = "application_tag_two"
    
    func test_01_init() {
        let key1 = SecuredKey(applicationTag: applicationTag1)
        XCTAssertNotNil(key1)
        let key2 = SecuredKey(applicationTag: applicationTag2)
        XCTAssertNotNil(key2)
        
        // Only delete the key2 for reading in further test
        SecuredKey.deleteKey(applicationTag: applicationTag2)
    }
    
    
    func test_02_read_key_from_previous_test_encryption() {
        
        let privateKey = SecuredKey.readKey(applicationTag: applicationTag1)!
        XCTAssertNotNil(privateKey)
        
        let key1 = SecuredKey(applicationTag: applicationTag1)
        
        let testString = "decrypted_text_for_testing".data(using: .utf8)!
        let encryptedUsingSecuredKey = key1?.encrypt(data: testString)
        
        let decryptedStringData = self.decrypt(data: encryptedUsingSecuredKey!, privateKey: privateKey, algorithm: .eciesEncryptionCofactorX963SHA256AESGCM)
        XCTAssertNotNil(decryptedStringData)
        let decryptedString = String(decoding: decryptedStringData!, as: UTF8.self)
        XCTAssertEqual(decryptedString, "decrypted_text_for_testing")
        
        SecuredKey.deleteKey(applicationTag: applicationTag1)
    }
    
    
    func test_03_test_encryption_using_secured_key() {
        
        let key = SecuredKey(applicationTag: applicationTag1)!
        let testString = "testing"
        
        let encrypted = key.encrypt(data: testString.data(using: .utf8)!)!
        let decrypted = key.decrypt(data: encrypted)!
        
        let decryptedString = String(decoding: decrypted, as: UTF8.self)
        
        XCTAssertNotNil(decryptedString)
        XCTAssertEqual(decryptedString, testString)
        
        SecuredKey.deleteKey(applicationTag: applicationTag1)
        SecuredKey.deleteKey(applicationTag: applicationTag2)
    }
    
    
    public func decrypt(data: Data, privateKey: SecKey, algorithm: SecKeyAlgorithm) -> Data? {
        
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            XCTFail("\(algorithm) is not supported on the device.")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) as Data?
        if let error = error {
            XCTFail("Failed to decrypt data: \(error)")
        }
        return decryptedData
    }
}
