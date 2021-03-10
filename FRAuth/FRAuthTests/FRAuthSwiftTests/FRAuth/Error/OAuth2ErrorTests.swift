// 
//  OAuth2ErrorTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class OAuth2ErrorTests: FRAuthBaseTest {

    
    func test_01_domain() {
        XCTAssertEqual(OAuth2Error.errorDomain, "com.forgerock.ios.frauth.oauth2")
    }
    

    func test_02_invalid_request() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=invalid_request"
        var error = OAuth2Error.invalidAuthorizeRequest(url)
        
        XCTAssertEqual(error.code, 1500001)
        XCTAssertEqual(error.errorCode, 1500001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_request")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500001)
        XCTAssertEqual(error.errorCode, 1500001)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_request")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_03_invalid_client() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=invalid_client"
        var error = OAuth2Error.invalidClient(url)
        
        XCTAssertEqual(error.code, 1500002)
        XCTAssertEqual(error.errorCode, 1500002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_client")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500002)
        XCTAssertEqual(error.errorCode, 1500002)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_client")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_04_invalid_grant() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=invalid_grant"
        var error = OAuth2Error.invalidGrant(url)
        
        XCTAssertEqual(error.code, 1500003)
        XCTAssertEqual(error.errorCode, 1500003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_grant")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500003)
        XCTAssertEqual(error.errorCode, 1500003)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_grant")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_05_unauthorized_client() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=unauthorized_client"
        var error = OAuth2Error.unauthorizedClient(url)
        
        XCTAssertEqual(error.code, 1500004)
        XCTAssertEqual(error.errorCode, 1500004)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unauthorized_client")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500004)
        XCTAssertEqual(error.errorCode, 1500004)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unauthorized_client")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_06_unsupported_grant_type() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=unsupported_grant_type"
        var error = OAuth2Error.unsupportedGrantType(url)
        
        XCTAssertEqual(error.code, 1500005)
        XCTAssertEqual(error.errorCode, 1500005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unsupported_grant_type")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500005)
        XCTAssertEqual(error.errorCode, 1500005)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unsupported_grant_type")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_07_unsupported_response_type() {
        let url = "frauth://com.forgerock.ios/login?error_description=Invalid%20data&error=unsupported_response_type"
        var error = OAuth2Error.unsupportedResponseType(url)
        
        XCTAssertEqual(error.code, 1500006)
        XCTAssertEqual(error.errorCode, 1500006)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unsupported_response_type")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500006)
        XCTAssertEqual(error.errorCode, 1500006)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unsupported_response_type")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Invalid data"))
    }
    
    
    func test_08_invalid_scope() {
        let url = "frauth://com.forgerock.ios/login?error_description=No%20scope%20requested%20and%20no%20default%20scope%20configured&error=invalid_scope"
        var error = OAuth2Error.invalidScope(url)
        
        XCTAssertEqual(error.code, 1500007)
        XCTAssertEqual(error.errorCode, 1500007)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_scope")
        XCTAssertTrue(error.localizedDescription.hasPrefix("No scope requested and no default scope configured"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500007)
        XCTAssertEqual(error.errorCode, 1500007)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "invalid_scope")
        XCTAssertTrue(error.localizedDescription.hasPrefix("No scope requested and no default scope configured"))
    }
    
    
    func test_09_missing_invalid_redirect_uri() {
        let error = OAuth2Error.missingOrInvalidRedirectURI(nil)
        
        XCTAssertEqual(error.code, 1500008)
        XCTAssertEqual(error.errorCode, 1500008)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "redirect_uri_error")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Missing or invalid redirect_uri"))
    }
    
    
    func test_10_access_denied() {
        let url = "frauth://com.forgerock.ios/login?error_description=Resource%20Owner%20did%20not%20authorize%20the%20request&error=access_denied"
        var error = OAuth2Error.accessDenied(url)
        
        XCTAssertEqual(error.code, 1500009)
        XCTAssertEqual(error.errorCode, 1500009)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "access_denied")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Resource Owner did not authorize the request"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500009)
        XCTAssertEqual(error.errorCode, 1500009)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "access_denied")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Resource Owner did not authorize the request"))
    }
    
    
    func test_11_other() {
        let url = "frauth://com.forgerock.ios/login?error_description=Other%20reason&error=other_reason"
        var error = OAuth2Error.other(url)
        
        XCTAssertEqual(error.code, 1500098)
        XCTAssertEqual(error.errorCode, 1500098)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "other_reason")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Other reason"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500098)
        XCTAssertEqual(error.errorCode, 1500098)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "other_reason")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Other reason"))
    }
    
    
    func test_12_unknown() {
        let url = "frauth://com.forgerock.ios/login"
        var error = OAuth2Error.unknown(url)
        
        XCTAssertEqual(error.code, 1500099)
        XCTAssertEqual(error.errorCode, 1500099)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unknown")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Unknown error"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: url)
        
        XCTAssertEqual(error.code, 1500099)
        XCTAssertEqual(error.errorCode, 1500099)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unknown")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Unknown error"))
        
        error = OAuth2Error.convertOAuth2Error(urlValue: "non-url format")
        
        XCTAssertEqual(error.code, 1500099)
        XCTAssertEqual(error.errorCode, 1500099)
        XCTAssertNotNil(error.errorUserInfo)
        XCTAssertEqual(error.error, "unknown")
        XCTAssertTrue(error.localizedDescription.hasPrefix("Unknown error"))
    }

}
