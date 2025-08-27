//
//  UserInfoTests.swift
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

class UserInfoTests: XCTestCase {
    
    func testValidUserInfoEncodingDecoding() {
        guard let response = FRTestStubResponseParser("OAuth2_UserInfo_Success"),
              let validUserInfo = response.jsonContent["responsePayload"] as? [String : Any] else {
            XCTFail("[UserInfoTests] Failed to load OAuth2_UserInfo_Success for mock response")
            return
        }

        let originalUserInfo = UserInfo(validUserInfo)

        // Test encoding
        let data = try! NSKeyedArchiver.archivedData(withRootObject: originalUserInfo, requiringSecureCoding: true)
        XCTAssertNotNil(data)

        // Test decoding
        let decodedUserInfo = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)
        XCTAssertNotNil(decodedUserInfo)

        // Verify data integrity
        XCTAssertEqual(decodedUserInfo?.sub, "james")
        XCTAssertEqual(decodedUserInfo?.name, "James Go")
        XCTAssertEqual(decodedUserInfo?.email, "james.go@forgerock.com")
        XCTAssertEqual(decodedUserInfo?.emailVerified, true)
        XCTAssertEqual(decodedUserInfo?.phoneNumberVerified, true)
    }

    func testEmptyUserInfoEncodingDecoding() {
        let emptyUserInfo: [String: Any] = [:]
        let userInfo = UserInfo(emptyUserInfo)

        let data = try! NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: true)
        let decodedUserInfo = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)

        XCTAssertNotNil(decodedUserInfo)
        XCTAssertNil(decodedUserInfo?.name)
        XCTAssertNil(decodedUserInfo?.email)
    }

    func testRejectUntrustedDataTypes() {
        // Test rejection of various untrusted data types
        let untrustedTypes: [String: Any] = [
            "valid_name": "John Doe",
            "malicious_array": [NSObject()], // Arrays with objects should be rejected
            "malicious_dict": ["key": NSObject()], // Nested objects should be rejected
            "valid_email": "test@example.com"
        ]

        let userInfo = UserInfo(untrustedTypes)

        XCTAssertThrowsError(try NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: true))
    }

    func testRejectInvalidDateFormats() {
        let invalidDateUserInfo: [String: Any] = [
            "name": "John Doe",
            "birthdate": "not-a-date", // Invalid date format
        ]

        let userInfo = UserInfo(invalidDateUserInfo)
        XCTAssertNil(userInfo.birthDate) // Invalid date should result in nil
    }

    func testNilValueHandling() {
        // Test that nil values are handled properly
        let userInfoWithNils: [String: Any] = [
            "name": "John Doe",
            "email": NSNull(), // Explicit null value
            "phone_number": "" // Empty string
        ]

        let userInfo = UserInfo(userInfoWithNils)
        let data = try! NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: true)
        let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.name, "John Doe")
        // Email should be nil due to NSNull
        XCTAssertNil(decoded?.email)
    }

    func testBooleanTypeValidation() {
        let booleanUserInfo: [String: Any] = [
            "name": "John Doe",
            "email_verified": 1, // Number instead of boolean
            "phone_number_verified": "true" // String instead of boolean
        ]

        let userInfo = UserInfo(booleanUserInfo)
        let data = try! NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: true)
        let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)

        XCTAssertNotNil(decoded)
        // Should handle type conversion gracefully
        XCTAssertFalse(decoded?.phoneNumberVerified ?? true) // Should default to false for invalid types
    }

    func testUserInfoWithAddressEncodingDecoding() {
        // Test UserInfo containing Address object
        let addressData: [String: Any] = [
            "street_address": "123 Main St",
            "locality": "Anytown",
            "postal_code": "12345"
        ]

        let userInfoData: [String: Any] = [
            "name": "John Doe",
            "email": "john@example.com",
            "address": addressData
        ]

        let userInfo = UserInfo(userInfoData)

        let data = try! NSKeyedArchiver.archivedData(withRootObject: userInfo, requiringSecureCoding: true)
        let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: UserInfo.self, from: data)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.name, "John Doe")
        XCTAssertNotNil(decoded?.address)
        XCTAssertEqual(decoded?.address?.streetAddress, "123 Main St")
    }
}
