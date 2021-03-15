// 
//  AuthErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class AuthErrorTests: FRAuthBaseTest {
    
    func test_01_domain() {
        XCTAssertEqual(AuthError.errorDomain, "com.forgerock.ios.frauth.authentication")
    }
    
    
    func test_02_invalid_token_response() {
        let error = AuthError.invalidTokenResponse([:])
        
        XCTAssertEqual(error.code, 1000006)
        XCTAssertEqual(error.errorCode, 1000006)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid token response: access_token, token_type, expires_in and scope are required, but missing in the response."))
    }
    
    
    func test_03_invalid_callback_response() {
        let error = AuthError.invalidCallbackResponse("")
        XCTAssertEqual(error.code, 1000007)
        XCTAssertEqual(error.errorCode, 1000007)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid callback response: ")
    }
    
    
    func test_04_unsupported_callback() {
        let error = AuthError.unsupportedCallback("")
        XCTAssertEqual(error.code, 1000008)
        XCTAssertEqual(error.errorCode, 1000008)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Unsupported callback: ")
    }
    
    
    func test_05_invalid_auth_service_response() {
        let error = AuthError.invalidAuthServiceResponse("")
        XCTAssertEqual(error.code, 1000009)
        XCTAssertEqual(error.errorCode, 1000009)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid AuthService response: ")
    }
    
    
    func test_06_invalid_oauth2_client() {
        let error = AuthError.invalidOAuth2Client
        XCTAssertEqual(error.code, 1000010)
        XCTAssertEqual(error.errorCode, 1000010)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid OAuth2Client: no OAuth2Client object was found")
    }
    
    
    func test_07_invalid_generic_type() {
        let error = AuthError.invalidGenericType
        XCTAssertEqual(error.code, 1000011)
        XCTAssertEqual(error.errorCode, 1000011)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Invalid generic type: Only Token, AccessToken, and FRUser are allowed")
    }
    
    
    func test_08_invalid_generic_type() {
        var error = AuthError.userAlreadyAuthenticated(true)
        XCTAssertEqual(error.code, 1000020)
        XCTAssertEqual(error.errorCode, 1000020)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "User is already authenticated")
        
        error = AuthError.userAlreadyAuthenticated(false)
        XCTAssertEqual(error.code, 1000020)
        XCTAssertEqual(error.errorCode, 1000020)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "User is already authenticated and has Session Token; use FRUser.currentUser.getAccessToken to obtian OAuth2 tokens")
    }
    
    
    func test_08_authentication_cancelled() {
        let error = AuthError.authenticationCancelled
        XCTAssertEqual(error.code, 1000030)
        XCTAssertEqual(error.errorCode, 1000030)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Authentication is cancelled")
    }
    
    
    func test_09_invalid_resume_uri() {
        let error = AuthError.authenticationCancelled
        XCTAssertEqual(error.code, 1000030)
        XCTAssertEqual(error.errorCode, 1000030)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "Authentication is cancelled")
    }
    
    
    func test_10_user_authentication_required() {
        let error = AuthError.userAuthenticationRequired
        XCTAssertEqual(error.code, 1000035)
        XCTAssertEqual(error.errorCode, 1000035)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.localizedDescription, "All user credentials are expired or invalid; user authentication is required")
    }
}
