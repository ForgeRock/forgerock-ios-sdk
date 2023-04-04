// 
//  URLUtilTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class URLUtilTests: FRABaseTests {

    func test_01_hotp_url_test() {
        // Given
        let url = URL(string: "otpauth://hotp/Forgerock:demo")!
        // Then
        let authType = url.getAuthType()
        XCTAssertEqual(authType, .hotp)
    }

    
    func test_02_totp_url_test() {
        // Given
        let url = URL(string: "otpauth://totp/Forgerock:demo")!
        // Then
        let authType = url.getAuthType()
        XCTAssertEqual(authType, .totp)
    }

    
    func test_03_push_url_test() {
        // Given
        let url = URL(string: "otpauth://push/Forgerock:demo")!
        // Then
        let authType = url.getAuthType()
        XCTAssertEqual(authType, .push)
    }

    
    func test_04_non_auth_url_test() {
        // Given
        let url = URL(string: "otpauth://www.forgerock.com/Forgerock:demo")!
        // Then
        let authType = url.getAuthType()
        XCTAssertEqual(authType, .unknown)
    }

    
    func test_05_missing_host_url_test() {
        // Given
        let url = URL(string: "otpauth:///Forgerock:demo")!
        // Then
        let authType = url.getAuthType()
        XCTAssertEqual(authType, .unknown)
    }
    
    func test_06_otpauth_url_test() {
        // Given
        let url = URL(string: "otpauth://hotp/Forgerock:demo")!
        // Then
        let uriType = url.getURIType()
        XCTAssertEqual(uriType, .otpauth)
    }
    
    func test_07_pushauth_url_test() {
        // Given
        let url = URL(string: "pushauth://hotp/Forgerock:demo")!
        // Then
        let uriType = url.getURIType()
        XCTAssertEqual(uriType, .pushauth)
    }
    
    func test_08_mfauth_url_test() {
        // Given
        let url = URL(string: "mfauth://hotp/Forgerock:demo")!
        // Then
        let uriType = url.getURIType()
        XCTAssertEqual(uriType, .mfauth)
    }
    
    func test_09_non_valid_scheme_url_test() {
        // Given
        let url = URL(string: "someauth:/hotp/Forgerock:demo")!
        // Then
        let uriType = url.getURIType()
        XCTAssertEqual(uriType, .unknown)
    }

}
