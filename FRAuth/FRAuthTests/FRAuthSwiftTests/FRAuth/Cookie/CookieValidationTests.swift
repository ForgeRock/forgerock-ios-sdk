// 
//  CookieValidationTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class CookieValidationTests: FRAuthBaseTest {
    
    
    //  MARK: - Domain validation
    
    func test_01_cookie_domain_validation_leading_dot() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/; Domain=.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://test.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://www.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.coma")!))
    }
    
    
    func test_02_cookie_domain_validation_without_leading_dot() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/; Domain=example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://test.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://www.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.coma")!))
    }
    
    
    func test_03_cookie_domain_validation_with_specific_subdomain() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://test.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://www.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.coma")!))
    }
    
    
    func test_04_cookie_domain_validation_without_domain() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://test.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://www.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.coma")!))
    }
    
    
    func test_05_cookie_domain_validation_subsub_domain() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/; Domain=.openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://fr.openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://test.fr.openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://test.test.fr.openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://test.forgerock.openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://testfr.openam.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://test.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://testfr.openamexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://www.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://example.coma")!))
        
    }
    
    
    //  MARK: - Path validation
    
    func test_05_cookie_path_validation() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc/def")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com/abc")!))
    }
    
    
    func test_06_cookie_path_validation_with_specific_path() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Path=/abc; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertFalse(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://openam.example.com/abcd")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc/def")!))
    }
    
    
    func test_07_cookie_path_validation_without_specified_path() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "http://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc")!))
        XCTAssertTrue(cookie.validateURL(URL(string: "http://openam.example.com/abc/def")!))
        XCTAssertFalse(cookie.validateURL(URL(string: "http://eexample.com/abc")!))
    }
    
    
    //  MARK: - isSecure validation
    
    func test_08_cookie_is_secure_validation_with_secured() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Secure; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "https://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "https://openam.example.com")!))
        XCTAssertFalse(cookie.validateIsSecure(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "HTTPS://openam.example.com")!))
        XCTAssertFalse(cookie.validateIsSecure(URL(string: "HTTP://openam.example.com")!))
        XCTAssertFalse(cookie.validateIsSecure(URL(string: "openam.example.com")!))
    }
    
    
    func test_08_cookie_is_secure_validation_with_none_secured() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "https://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "https://openam.example.com")!))
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "http://openam.example.com")!))
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "HTTPS://openam.example.com")!))
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "HTTP://openam.example.com")!))
        XCTAssertTrue(cookie.validateIsSecure(URL(string: "openam.example.com")!))
    }
    
    
    //  MARK: - isExpired validation
    
    func test_09_cookie_is_expired_validation_expired() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Expires=Wed, 21 Oct 1999 01:00:00 GMT; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "https://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        XCTAssertTrue(cookie.isExpired)
    }
    
    
    func test_10_cookie_is_expired_validation_not_expired() {
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Expires=Wed, 21 Oct 2021 01:00:00 GMT; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: URL(string: "https://openam.example.com")!)
        guard let cookie = cookies.first else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        XCTAssertFalse(cookie.isExpired)
    }
}
