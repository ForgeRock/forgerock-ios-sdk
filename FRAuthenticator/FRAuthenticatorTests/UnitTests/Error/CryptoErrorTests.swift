// 
//  CryptoErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class CryptoErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(CryptoError.errorDomain, "com.forgerock.ios.frauthenticator.crypto")
    }
    
    
    func test_02_invalid_param() {
        let error = CryptoError.invalidParam("secret, and challenge")
        
        XCTAssertEqual(error.code, 1200000)
        XCTAssertEqual(error.errorCode, 1200000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid or fail to decode parameters: secret, and challenge")
    }
    
    
    func test_03_fail_to_convert_data() {
        let error = CryptoError.failToConvertData
        
        XCTAssertEqual(error.code, 1200001)
        XCTAssertEqual(error.errorCode, 1200001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Failed to convert given data")
    }
    
    
    func test_04_invalid_jwt() {
        let error = CryptoError.invalidJWT
        
        XCTAssertEqual(error.code, 1200002)
        XCTAssertEqual(error.errorCode, 1200002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Given JWT is invalid")
    }
    
    
    func test_05_unsupported_jwt_type() {
        let error = CryptoError.unsupportedJWTType
        
        XCTAssertEqual(error.code, 1200003)
        XCTAssertEqual(error.errorCode, 1200003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Given JWT type is not supported")
    }
}
