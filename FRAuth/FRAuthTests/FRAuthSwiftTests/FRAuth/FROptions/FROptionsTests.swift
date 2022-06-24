// 
//  FROptionsTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
import FRAuth
import FRCore

class FROptionsTests: FRAuthBaseTest {
    
    override func setUp() {
        //leave empty
    }
    
    func testDynamicConfigSessionOnly() {
        do {
            let options = FROptions(forgerock_url: "https://openam-forgerock-sdks/am",
                                    forgerock_realm: "alpha",
                                    forgerock_cookie_name: "CookieName",
                                    forgerock_auth_service_name: "Login",
                                    forgerock_registration_service_name: "Register")
            
            try FRAuth.start(options: options)
            
            XCTAssertTrue(options.forgerock_auth_service_name == "Login")
            XCTAssertTrue(options.forgerock_registration_service_name == "Register")
            XCTAssertTrue(options.forgerock_enable_cookie)
            XCTAssertTrue(options.forgerock_cookie_name == "CookieName")
            XCTAssertTrue(options.forgerock_realm == "alpha")
            XCTAssertTrue(options.forgerock_url == "https://openam-forgerock-sdks/am")
            XCTAssertNil(options.forgerock_oauth_client_id)
            XCTAssertNil(options.forgerock_oauth_redirect_uri)
            XCTAssertNil(options.forgerock_oauth_scope)
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
        }
        catch {
            XCTFail()
        }
    }
    
    func testDynamicConfigBasicOAuth() {
        do {
            let options = FROptions(forgerock_url: "https://openam-forgerock-sdks/am",
                                    forgerock_realm: "alpha",
                                    forgerock_auth_service_name: "Login",
                                    forgerock_registration_service_name: "Register",
                                    forgerock_oauth_client_id: "iosClient",
                                    forgerock_oauth_redirect_uri: "frauth://com.forgerock.ios.frexample",
                                    forgerock_oauth_scope: "openid profile email address")
            
            try FRAuth.start(options: options)
            
            XCTAssertTrue(options.forgerock_auth_service_name == "Login")
            XCTAssertTrue(options.forgerock_registration_service_name == "Register")
            XCTAssertTrue(options.forgerock_enable_cookie)
            XCTAssertTrue(options.forgerock_cookie_name == "iPlanetDirectoryPro")
            XCTAssertTrue(options.forgerock_realm == "alpha")
            XCTAssertTrue(options.forgerock_url == "https://openam-forgerock-sdks/am")
            XCTAssertTrue(options.forgerock_oauth_client_id == "iosClient")
            XCTAssertTrue(options.forgerock_oauth_redirect_uri == "frauth://com.forgerock.ios.frexample")
            XCTAssertTrue(options.forgerock_oauth_scope == "openid profile email address")
            
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
        }
        catch {
            XCTFail()
        }
    }
    
    func testDynamicConfigComplete() {
        
    }
}
