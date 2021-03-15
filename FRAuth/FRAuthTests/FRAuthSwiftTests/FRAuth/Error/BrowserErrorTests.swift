// 
//  BrowserErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class BrowserErrorTests: FRAuthBaseTest {

    func test_01_domain() {
        XCTAssertEqual(BrowserError.errorDomain, "com.forgerock.ios.frauth.browser")
    }
    
    
    func test_02_external_user_agent_failure() {
        let error = BrowserError.externalUserAgentFailure
        
        XCTAssertEqual(error.code, 1400000)
        XCTAssertEqual(error.errorCode, 1400000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Fail to luanch the external user-agent"))
    }
    
    
    func test_02_external_user_agent_in_progress() {
        let error = BrowserError.externalUserAgentAuthenticationInProgress
        
        XCTAssertEqual(error.code, 1400001)
        XCTAssertEqual(error.errorCode, 1400001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("External user-agent authentication is currently in progress"))
    }
    
    
    func test_03_external_user_agent_cancelled() {
        let error = BrowserError.externalUserAgentCancelled
        
        XCTAssertEqual(error.code, 1400002)
        XCTAssertEqual(error.errorCode, 1400002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("External user-agent authentication is cancelled"))
    }
}
