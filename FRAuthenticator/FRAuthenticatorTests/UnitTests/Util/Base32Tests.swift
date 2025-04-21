// 
//  Base32Tests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class Base32Tests: FRABaseTests {

    func test_01_base32_encode() {
        
        let string = "TestString!@#"
        
        let encodedString: String? = string.base32Encode()
        let encodedData: Data? = string.base32Encode()
        XCTAssertNotNil(encodedString)
        XCTAssertNotNil(encodedData)
    }
    
    
    func test_02_base32_decode() {
        
        let encoded = "IZXXEZ3FKI======"
        
        let decodedString: String? = encoded.base32Decode()
        let decodedData: Data? = encoded.base32Decode()
        XCTAssertNotNil(decodedString)
        XCTAssertNotNil(decodedData)
    }
    
    
    func test_03_base32_require_padding() {
        
        let string = "FR!"
        
        let encodedString: String? = string.base32Encode()
        XCTAssertNotNil(encodedString)
        XCTAssertEqual(encodedString, "IZJCC===")
        
        let encoded = "IZJCC==="
        let decodedString: String? = encoded.base32Decode()
        XCTAssertNotNil(decodedString)
        XCTAssertEqual(decodedString, string)
    }
    
    
    func test_04_base32_special_chars() {
        
        let string = "TestString!@#"
        
        let encodedString: String? = string.base32Encode()
        guard let encoded = encodedString else {
            XCTFail("Failed to encode string")
            return
        }
        
        let decodedString: String? = encoded.base32Decode()
        XCTAssertNotNil(decodedString)
        XCTAssertEqual(decodedString, string)
    }    
}
