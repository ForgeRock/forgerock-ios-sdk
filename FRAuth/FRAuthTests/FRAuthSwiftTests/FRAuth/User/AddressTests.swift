// 
//  AddressTests.swift
//  FRAuth
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
import Foundation
@testable import FRAuth

class AddressTests: XCTestCase {
    
    func testValidAddressEncodingDecoding() {
        guard let response = FRTestStubResponseParser("OAuth2_UserInfo_Success"),
              let validUserInfo = response.jsonContent["responsePayload"] as? [String : Any],
              let validAddress = validUserInfo["address"] as? [String : Any] else {
            XCTFail("[UserInfoTests] Failed to load OAuth2_UserInfo_Success for mock response")
            return
        }
        
        let originalAddress = Address(validAddress)
        
        // Test encoding with secure coding
        let data = try! NSKeyedArchiver.archivedData(withRootObject: originalAddress, requiringSecureCoding: true)
        XCTAssertNotNil(data)
        
        // Test decoding
        let decodedAddress = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Address.self, from: data)
        XCTAssertNotNil(decodedAddress)
        
        // Verify data integrity
        XCTAssertEqual(decodedAddress?.streetAddress, "201 Mission St")
        XCTAssertEqual(decodedAddress?.locality, "San Francisco")
        XCTAssertEqual(decodedAddress?.region, "CA")
        XCTAssertEqual(decodedAddress?.postalCode, "94105")
        XCTAssertEqual(decodedAddress?.country, "US")
    }
    
    func testEmptyAddressEncodingDecoding() {
        let emptyAddress: [String: Any] = [:]
        let address = Address(emptyAddress)
        
        let data = try! NSKeyedArchiver.archivedData(withRootObject: address, requiringSecureCoding: true)
        let decodedAddress = try! NSKeyedUnarchiver.unarchivedObject(ofClass: Address.self, from: data)
        
        XCTAssertNotNil(decodedAddress)
        XCTAssertNil(decodedAddress?.streetAddress)
        XCTAssertNil(decodedAddress?.locality)
    }
    
    func testRejectMaliciousAddressObjects() {
        let maliciousAddress: [String: Any] = [
            "street_address": "123 Main St",
            "malicious_code": NSObject(), // Should be rejected
            "locality": "Anytown"
        ]
        
        let address = Address(maliciousAddress)
        
        // Should fail with secure coding
        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: address, requiringSecureCoding: true)) { _ in }
    }
    
    func testRejectNestedMaliciousObjects() {
        let nestedMaliciousAddress: [String: Any] = [
            "street_address": "123 Main St",
            "nested_attack": [
                "level1": [
                    "level2": NSObject() // Deeply nested malicious object
                ]
            ]
        ]
        
        let address = Address(nestedMaliciousAddress)
        
        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: address, requiringSecureCoding: true))
    }
    
}
