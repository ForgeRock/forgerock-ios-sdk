// 
//  TokenErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class TokenErrorTests: FRAuthBaseTest {
    
    func test_01_domain() {
        XCTAssertEqual(TokenError.errorDomain, "com.forgerock.ios.frauth.token")
    }
    
    
    func test_02_failed_to_parse_token() {
        let error = TokenError.failToParseToken("failure")
        
        XCTAssertEqual(error.code, 3000000)
        XCTAssertEqual(error.errorCode, 3000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Failed to persist Token: failure"))
    }
    
    
    func test_03_null_refresh_token() {
        let error = TokenError.nullRefreshToken
        
        XCTAssertEqual(error.code, 3000001)
        XCTAssertEqual(error.errorCode, 3000001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid refresh_token: refresh_token is not found"))
    }
    
    
    func test_04_null_token() {
        let error = TokenError.nullToken
        
        XCTAssertEqual(error.code, 3000002)
        XCTAssertEqual(error.errorCode, 3000002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid token: token is not found"))
    }
}
