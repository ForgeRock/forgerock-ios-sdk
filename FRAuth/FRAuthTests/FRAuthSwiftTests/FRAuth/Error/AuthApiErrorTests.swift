// 
//  AuthApiErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AuthApiErrorTests: FRAuthBaseTest {
    
    
    func test_01_domain() {
        XCTAssertEqual(AuthApiError.errorDomain, "com.forgerock.ios.frauth.authapierror")
    }
    
    
    func test_02_api_request_failure() {
        let error = AuthApiError.apiRequestFailure(nil, nil, nil)
        XCTAssertEqual(error.code, 1300000)
        XCTAssertEqual(error.errorCode, 1300000)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Request failed"))
    }
    
    
    func test_03_authentication_timeout() {
        let error = AuthApiError.authenticationTimout("Unauthorized", "Session has timed out", nil, nil)
        XCTAssertEqual(error.code, 1300001)
        XCTAssertEqual(error.errorCode, 1300001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Authentication timed out"))
    }
    
    
    func test_04_api_failure_with_message() {
        
        let jsonStr = """
        {
            "code": 400,
            "reason": "Bad Request",
            "message": "No Configuration found"
        }
        """
        let error = AuthApiError.apiFailureWithMessage("Bad Request", "No Configuration found", 400, self.parseStringToDictionary(jsonStr))
        XCTAssertEqual(error.code, 1300002)
        XCTAssertEqual(error.errorCode, 1300002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("No Configuration found"))
    }
    
    
    func test_05_suspended_auth_session_error() {
        
        let jsonStr = """
        {
            "code": 401,
            "reason": "Unauthorized",
            "message": "org.forgerock.openam.auth.nodes.framework.token.SuspendedAuthSessionException: Token not found. It may have expired."
        }
        """
        let error = AuthApiError.suspendedAuthSessionError("Unauthorized", "org.forgerock.openam.auth.nodes.framework.token.SuspendedAuthSessionException: Token not found. It may have expired.", 401, self.parseStringToDictionary(jsonStr))
        XCTAssertEqual(error.code, 1300003)
        XCTAssertEqual(error.errorCode, 1300003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, " Token not found. It may have expired.")
    }
}
