// 
//  NotificationErrorTests.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuthenticator

class NotificationErrorTests: FRABaseTests {

    func test_01_domain() {
        XCTAssertEqual(NotificationError.errorDomain, "com.forgerock.ios.frauthenticator.notification")
    }
    
    func test_02_invalid_payload() {
        let error = NotificationError.invalidPayload("something is missing")
        
        XCTAssertEqual(error.code, 7000000)
        XCTAssertEqual(error.errorCode, 7000000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid notification payload: something is missing")
    }
}
