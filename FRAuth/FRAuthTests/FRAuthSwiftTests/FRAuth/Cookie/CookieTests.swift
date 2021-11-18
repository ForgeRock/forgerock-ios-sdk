// 
//  CookieTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class CookieTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        self.shouldLoadMockResponses = true
    }
    
    
    func test_01_validate_cookie_after_login() {
           
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performLogin()
        
        // Given last authentication request is OAuth2 token endpoint which should contain Session Token Cookie
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(cookieHeader)
        XCTAssertTrue(cookieHeader!.contains(sessionToken!))
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_02_validate_cookie_from_existing_session() {
        
        // Start SDK
        self.startSDK()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to get user object")
            return
        }
        
        // Given
        let ex = self.expectation(description: "Get User Info")
        var receivedUserInfo: UserInfo? = nil
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(userInfo)
            XCTAssertNil(error)
            receivedUserInfo = userInfo
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertNotNil(receivedUserInfo)
        
        // With /userinfo request
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(cookieHeader)
        XCTAssertTrue(cookieHeader!.contains(sessionToken!))
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_03_validate_cookie_does_not_injected_with_disabled() {
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to get Config obj")
            return
        }
        
        self.config.serverConfig = ServerConfigBuilder(url: serverConfig.baseURL, realm: serverConfig.realm).set(timeout: serverConfig.timeout).set(enableCookie: false).build()
        
        // Start SDK
        self.startSDK()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to get user object")
            return
        }
        
        // Given
        let ex = self.expectation(description: "Get User Info")
        var receivedUserInfo: UserInfo? = nil
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(userInfo)
            XCTAssertNil(error)
            receivedUserInfo = userInfo
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertNotNil(receivedUserInfo)
        
        // With /userinfo request
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let sessionToken = FRSession.currentSession?.sessionToken?.value
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNotNil(sessionToken)
        XCTAssertNil(cookieHeader)
    }
    
    
    func test_04_validate_no_persistent_cookie_when_disabled() {
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to get Config obj")
            return
        }
        
        self.config.serverConfig = ServerConfigBuilder(url: serverConfig.baseURL, realm: serverConfig.realm).set(timeout: serverConfig.timeout).set(enableCookie: false).build()
        
        // Start SDK
        self.startSDK()
        
        self.performLogin()
        
        // Given last authentication request is OAuth2 token endpoint which should contain Session Token Cookie
        let request = FRTestNetworkStubProtocol.requestHistory.last
        XCTAssertNotNil(request)
        
        // Then
        let cookieHeader = request?.allHTTPHeaderFields?.string("Cookie")
        XCTAssertNil(cookieHeader)
        
        // Also
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    
    func test_05_validate_cookie_deleted_after_successful_logout() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Then
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    
    func test_06_validate_cookie_deleted_after_unsuccessful_logout() {
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()

        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Failure",
                                "OAuth2_Token_Revoke_Success"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Then
        guard let count = self.config.keychainManager?.cookieStore.allItems()?.count else {
            return
        }
        XCTAssertEqual(count, 0)
    }
    
    func test_07_validate_cookie_is_stored_and_unarchived_Correctly() {
        self.startSDK()

        self.performLogin()
        let url = URL(string: "https://openam.example.com")!
        
        let setCookie: [String: String] = ["Set-Cookie":"iPlanetDirectoryPro=token; Expires=Wed, 21 Oct 2022 01:00:00 GMT; Domain=openam.example.com"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookie, for: url)
        
        guard let cookie = cookies.first, let frAuth = FRAuth.shared else {
            XCTFail("Failed to parse Cookies from response header")
            return
        }
        
        if #available(iOS 11.0, *) {
            if let properties = cookie.properties, let frHTTPCookie = FRHTTPCookie(with: properties), let cookieData = try? NSKeyedArchiver.archivedData(withRootObject: frHTTPCookie, requiringSecureCoding: true) {
                XCTAssertNotNil(cookieData)
                frAuth.keychainManager.cookieStore.set(cookieData, key: cookie.name + "-" + cookie.domain)
            }
        } else {
            let cookieData = NSKeyedArchiver.archivedData(withRootObject: cookie)
            XCTAssertNotNil(cookieData)
            frAuth.keychainManager.cookieStore.set(cookieData, key: cookie.name + "-" + cookie.domain)
        }
        
        guard let cookieItems = frAuth.keychainManager.cookieStore.allItems() else {
            XCTFail("Failed to retrieve Cookies")
            return
        }
        
        for cookieObj in cookieItems {
            if #available(iOS 11.0, *) {
                do {
                if let cookieData = cookieObj.value as? Data, let unArchivedcookie = try NSKeyedUnarchiver.unarchivedObject(ofClass: FRHTTPCookie.self, from: cookieData) {
                    XCTAssertEqual(cookie.expiresDate, unArchivedcookie.expiresDate)
                    XCTAssertEqual(cookie.comment, unArchivedcookie.comment)
                    XCTAssertEqual(cookie.commentURL, unArchivedcookie.commentURL)
                    XCTAssertEqual(cookie.name, unArchivedcookie.name)
                    XCTAssertEqual(cookie.value, unArchivedcookie.value)
                    XCTAssertEqual(cookie.path, unArchivedcookie.path)
                    XCTAssertEqual(cookie.domain, unArchivedcookie.domain)
                    XCTAssertEqual(cookie.isSecure, unArchivedcookie.isSecure)
                    XCTAssertEqual(cookie.isSessionOnly, unArchivedcookie.isSessionOnly)
                    XCTAssertEqual(cookie.isHTTPOnly, unArchivedcookie.isHTTPOnly)
                    checkCookie(unArchivedcookie)
                }
                } catch {
                    FRLog.e("[Cookies] unarchiving failed with error: \(error.localizedDescription)")
                }
            }
            else {
                if let cookieData = cookieObj.value as? Data, let cookie = NSKeyedUnarchiver.unarchiveObject(with: cookieData) as? HTTPCookie {
                    checkCookie(cookie)
                }
            }
        }
        
        func checkCookie(_ cookie: HTTPCookie) {
            // When Cookie is expired, remove it from the Cookie Store
            if cookie.isExpired {
                frAuth.keychainManager.cookieStore.delete(cookie.name + "-" + cookie.domain)
                XCTFail("[Cookies] Delete - Expired - Cookie Name: \(cookie.name)")
            }
            else {
                if !cookie.validateIsSecure(url) {
                    XCTFail("[Cookies] Ignore - isSecure validation failed - Domain: \(url)\n\nCookie: \(cookie.name)")
                }
                else if !cookie.validateURL(url) {
                    XCTFail("[Cookies] Ignore - Domain validation failed - Domain: \(url)\n\nCookie: \(cookie.name)")
                }
                else {
                    print("[Cookies] To be Injected for the request - Cookie Name: \(cookie.name) | Cookie Value \(cookie.value)")
                }
            }
        }
        
    }
}
