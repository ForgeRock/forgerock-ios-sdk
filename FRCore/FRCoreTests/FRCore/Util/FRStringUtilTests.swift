// 
//  FRStringUtilTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class FRStringUtilTests: FRBaseTestCase {

    func test_01_base64_encode_decode() {
        let plain = "testing_base64"
        let encoded = plain.base64Encoded()
        
        XCTAssertNotNil(encoded)
        XCTAssertEqual(encoded?.base64Decoded(), plain)
    }
    
    
    func test_02_is_base64_encoded() {
        let encoded = "dGVzdGluZ19iYXNlNjQ="
        XCTAssertTrue(encoded.isBase64Encoded())
        
        let nonEncoded = "testing_base64"
        XCTAssertFalse(nonEncoded.isBase64Encoded())
    }
    
    
    func test_03_base64_encode_url_safe() {
        let plain = "http://openam.example.com:8081/openam/json/push/sns/message?_action=authenticate"
        let encoded = plain.base64Encoded()
        let urlEncoded = plain.base64URLSafeEncoded()
        
        XCTAssertNotNil(encoded)
        XCTAssertNotNil(urlEncoded)
        
        XCTAssertEqual(encoded?.base64Decoded(), plain)
        let urlDecoded = urlEncoded?.decodeURL()
        XCTAssertNotNil(urlDecoded)
        let urlDecodedStr = String(bytes: urlDecoded!, encoding: .utf8)
        XCTAssertEqual(urlDecodedStr, plain)
    }
    
    
    func test_04_url_safe_encoding() {
        let plain = "testing+/="
        let urlSafe = plain.urlSafeEncoding()
        XCTAssertEqual(urlSafe, "testing-_")
    }
    
    
    func test_05_url_safe_decoding() {
        let encoded = "testing-_"
        let decoded = encoded.urlSafeDecoding()
        XCTAssertEqual(decoded, "testing+/")
    }
}
