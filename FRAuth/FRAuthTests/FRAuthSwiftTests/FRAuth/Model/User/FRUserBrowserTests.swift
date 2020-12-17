//// 
////  FRUserBrowserTests.swift
////  FRAuthTests
////
////  Copyright (c) 2020 ForgeRock. All rights reserved.
////
////  This software may be modified and distributed under the terms
////  of the MIT license. See the LICENSE file for details.
////
//
//
//import XCTest
//
//class FRUserBrowserTests: FRBaseTest {
//    
//    override func setUp() {
//        self.configFileName = "Config"
//        super.setUp()
//    }
//    
//    
//    func test_01_fruser_browser_init() {
//        FRAuth.shared = nil
//        
//        //  Given no SDK init
//        let builder = FRUser.browser()
//        XCTAssertNil(builder)
//        
//        //  When
//        self.startSDK()
//        
//        //  Then
//        let builder2 = FRUser.browser()
//        XCTAssertNotNil(builder2)
//        
//        //  Can also
//        let builder3 = FRUser.browser()
//        XCTAssertNotNil(builder3)
//        
//        //  If
//        let browser = builder2?.build()
//        
//        //  Then
//        let builder4 = FRUser.browser()
//        XCTAssertNil(builder4)
//        XCTAssertNotNil(Browser.currentBrowser)
//        XCTAssertEqual(Browser.currentBrowser, browser)
//    }
//    
//    
//    func test_02_fruser_browser_login_and_logout_success() {
//        
//        //  SDK init
//        self.startSDK()
//        
//        // Set mock responses
//        self.loadMockResponses(["OAuth2_Token_Success",
//                                "AM_Session_Logout_Success",
//                                "OAuth2_Token_Revoke_Success",
//                                "OAuth2_EndSession_Success"])
//        
//        let ex = self.expectation(description: "Browser Login")
//        let _ = FRUser.browser()?.set(browserType: .authSession).build().login(completion: { (user, error) in
//            XCTAssertNil(error)
//            XCTAssertNotNil(user)
//            ex.fulfill()
//        })
//        //  Inject authorization_code to mimic browser authentication
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
//        waitForExpectations(timeout: 60, handler: nil)
//        
//        XCTAssertNotNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//        
//        FRUser.currentUser?.logout()
//        
//        // Sleep for 5 seconds to wait for async logout requests go through
//        sleep(5)
//        
//        XCTAssertNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//    }
//    
//    
//    func test_03_fruser_browser_login_and_logout_end_session_failure() {
//        
//        //  SDK init
//        self.startSDK()
//        
//        // Set mock responses
//        self.loadMockResponses(["OAuth2_Token_Success",
//                                "OAuth2_Token_Revoke_Success",
//                                "OAuth2_EndSession_Failure"])
//        
//        let ex = self.expectation(description: "Browser Login")
//        let _ = FRUser.browser()?.set(browserType: .authSession).build().login(completion: { (user, error) in
//            XCTAssertNotNil(user)
//            XCTAssertNil(error)
//            ex.fulfill()
//        })
//        //  Inject authorization_code to mimic browser authentication
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
//        waitForExpectations(timeout: 60, handler: nil)
//        
//        XCTAssertNotNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//        
//        FRUser.currentUser?.logout()
//        
//        // Sleep for 5 seconds to wait for async logout requests go through
//        sleep(5)
//        
//        XCTAssertNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//    }
//    
//    
//    func test_04_consecutive_browser_login_with_different_browser_type() {
//        
//        //  TODO: - Temporarily disable this test due to UI issue
////        //  SDK init
////        self.startSDK()
////
////        // Set mock responses
////        self.loadMockResponses(["OAuth2_Token_Success",
////                                "OAuth2_Token_Revoke_Success",
////                                "OAuth2_EndSession_Success",
////                                "OAuth2_Token_Success"])
////
////        var ex = self.expectation(description: "Browser Login")
////        let _ = FRUser.browser()?.set(browserType: .authSession).build().login(completion: { (user, error) in
////            XCTAssertNotNil(user)
////            XCTAssertNil(error)
////            ex.fulfill()
////        })
////        //  Inject authorization_code to mimic browser authentication
////        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
////        waitForExpectations(timeout: 60, handler: nil)
////
////        XCTAssertNotNil(FRUser.currentUser)
////        XCTAssertNil(Browser.currentBrowser)
////
////        FRUser.currentUser?.logout()
////
////        // Sleep for 5 seconds to wait for async logout requests go through
////        sleep(5)
////
////        XCTAssertNil(FRUser.currentUser)
////        XCTAssertNil(Browser.currentBrowser)
////
////        ex = self.expectation(description: "Browser Login")
////        let _ = FRUser.browser()?.set(browserType: .sfViewController).build().login(completion: { (user, error) in
////            XCTAssertNotNil(user)
////            XCTAssertNil(error)
////            ex.fulfill()
////        })
////        //  Inject authorization_code to mimic browser authentication
////        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
////        waitForExpectations(timeout: 60, handler: nil)
////
////        XCTAssertNotNil(FRUser.currentUser)
////        XCTAssertNil(Browser.currentBrowser)
//    }
//    
//    
//    func test_05_native_login_and_following_browser_login() {
//        
//        //  SDK init
//        self.startSDK()
//        
//        //  Perform native Login
//        self.performUsernamePasswordLogin()
//        
//        //  Validate
//        XCTAssertNotNil(FRUser.currentUser)
//        
//        
//        // Set mock responses
//        self.loadMockResponses(["AM_Session_Logout_Success",
//                                "OAuth2_Token_Revoke_Success",
//                                "OAuth2_EndSession_Success",
//                                "OAuth2_Token_Success",
//                                "OAuth2_Token_Revoke_Success",
//                                "OAuth2_EndSession_Success"])
//        
//        //  Then
//        FRUser.currentUser?.logout()
//        sleep(5)
//        XCTAssertNil(FRUser.currentUser)
//        
//        //  Get top VC
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//        
//        //  Continue with Browser
//        let ex = self.expectation(description: "Browser Login")
//        let _ = FRUser.browser()?.set(browserType: .sfViewController).set(presentingViewController: vc).build().login(completion: { (user, error) in
//            XCTAssertNotNil(user)
//            XCTAssertNil(error)
//            ex.fulfill()
//        })
//        //  Inject authorization_code to mimic browser authentication
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
//        waitForExpectations(timeout: 60, handler: nil)
//        
//        XCTAssertNotNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//        
//        //  Then
//        FRUser.currentUser?.logout()
//        sleep(5)
//        XCTAssertNil(FRUser.currentUser)
//    }
//
//    
//    func test_06_browser_login_and_following_native_login() {
//        
//        //  SDK init
//        self.startSDK()
//        
//        
//        // Set mock responses
//        self.loadMockResponses(["OAuth2_Token_Success",
//                                "OAuth2_Token_Revoke_Success",
//                                "OAuth2_EndSession_Success"])
//        
//        //  Get top VC
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//        
//        //  Start with Browser
//        let ex = self.expectation(description: "Browser Login")
//        let _ = FRUser.browser()?.set(browserType: .sfViewController).set(presentingViewController: vc).build().login(completion: { (user, error) in
//            XCTAssertNotNil(user)
//            XCTAssertNil(error)
//            ex.fulfill()
//        })
//        //  Inject authorization_code to mimic browser authentication
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
//        waitForExpectations(timeout: 60, handler: nil)
//        
//        XCTAssertNotNil(FRUser.currentUser)
//        XCTAssertNil(Browser.currentBrowser)
//        
//        //  Then
//        FRUser.currentUser?.logout()
//        sleep(5)
//        XCTAssertNil(FRUser.currentUser)
//        
//        //  Continue with native
//        self.performUsernamePasswordLogin()
//        
//        XCTAssertNotNil(FRUser.currentUser)
//    }
//    
//    
//    func test_07_should_manual_cleanup() {
//        self.shouldCleanup = true
//    }
//}
