// 
//  SocialLoginErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class SocialLoginErrorTests: FRAuthBaseTest {
    
    func test_01_domain() {
        XCTAssertEqual(SocialLoginError.errorDomain, "com.forgerock.ios.frauth.sociallogin")
    }
    
    
    func test_02_not_supported() {
        let error = SocialLoginError.notSupported("not supported message")
        XCTAssertEqual(error.code, 1600000)
        XCTAssertEqual(error.errorCode, 1600000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Selected Social Login Provider is not supported: not supported message")
    }
    
    
    func test_03_unsupported_credentials() {
        let error = SocialLoginError.unsupportedCredentials("not supported credentials")
        XCTAssertEqual(error.code, 1600001)
        XCTAssertEqual(error.errorCode, 1600001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Returned credentials is not supported: not supported credentials")
    }
    
    
    func test_04_cancelled() {
        let error = SocialLoginError.cancelled
        XCTAssertEqual(error.code, 1600002)
        XCTAssertEqual(error.errorCode, 1600002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Operation is cancelled")
    }
    
    
    func test_05_missing_handler() {
        let error = SocialLoginError.missingIdPHandler
        XCTAssertEqual(error.code, 1600003)
        XCTAssertEqual(error.errorCode, 1600003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "IdPHandler is missing; the given provider does not match with any of default IdPHandler implementation")
    }
}
