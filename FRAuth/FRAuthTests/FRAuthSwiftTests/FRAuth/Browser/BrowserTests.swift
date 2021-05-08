////
////  BrowserTests.swift
////  FRAuthTests
////
////  Copyright (c) 2020 ForgeRock. All rights reserved.
////
////  This software may be modified and distributed under the terms
////  of the MIT license. See the LICENSE file for details.
////
//
//import XCTest
//@testable import FRAuth
//
//class BrowserTests: FRAuthBaseTest {
//
//    override func setUp() {
//        self.configFileName = "Config"
//        super.setUp()
//    }
//
//    func test_01_browser_init() {
//
//        //  Start SDK
//        self.startSDK()
//
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        let vc = UIViewController()
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//
//        XCTAssertNil(Browser.currentBrowser)
//        XCTAssertNotNil(browser)
//        XCTAssertEqual(browser.browserType, .sfViewController)
//        XCTAssertEqual(browser.presentingViewController, vc)
//        XCTAssertEqual(browser.customParam.count, 0)
//        XCTAssertFalse(browser.isInProgress)
//        XCTAssertNil(browser.currentSession)
//        XCTAssertNil(browser.completionCallback)
//    }
//
//
//    func test_02_browser_login_already_authenticated() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Perform Login
//        self.performLogin()
//        XCTAssertNotNil(FRUser.currentUser?.token)
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with already authenticated session
//        let vc = UIViewController()
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//
//        //  When
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let authError = error as? AuthError {
//                switch authError {
//                case .userAlreadyAuthenticated:
//                    break
//                default:
//                    XCTFail("While expecting AuthError.userAlreadyAuthenticated; failed with different error \(authError.localizedDescription)")
//                    break
//                }
//            }
//
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_03_browser_login_already_in_progress_from_another_instance() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given that another Browser instance is constructed and running
//        let firstBrowser = FRUser.browser()?.build()
//        XCTAssertNotNil(Browser.currentBrowser)
//        firstBrowser?.login(completion: { (user, error) in
//        })
//
//        let vc = UIViewController()
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//        XCTAssertEqual(firstBrowser, Browser.currentBrowser)
//
//        //  When
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertTrue(Browser.currentBrowser?.isInProgress ?? false)
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let browserError = error as? BrowserError {
//                switch browserError {
//                case .externalUserAgentAuthenticationInProgress:
//                    break
//                default:
//                    XCTFail("While expecting BrowserError.externalUserAgentAuthenticationInProgress; failed with different error \(browserError.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting BrowserError.externalUserAgentAuthenticationInProgress; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_04_same_browser_login_already_in_progress() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with already login process initiated
//        let vc = UIViewController()
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//        browser.login { (user, error) in
//        }
//
//        //  When
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let browserError = error as? BrowserError {
//                switch browserError {
//                case .externalUserAgentAuthenticationInProgress:
//                    break
//                default:
//                    XCTFail("While expecting BrowserError.externalUserAgentAuthenticationInProgress; failed with different error \(browserError.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting BrowserError.externalUserAgentAuthenticationInProgress; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_05_login_safari_vc_validate_auth_code() {
//
//        //  Start SDK
//        self.startSDK()
//
//        // Set mock responses
//        self.loadMockResponses(["OAuth2_Token_Success"])
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with SFSafariViewController type of Browser object
//
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//        Browser.currentBrowser = browser
//
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNotNil(user)
//            XCTAssertNil(error)
//            ex.fulfill()
//        }
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login?code=testcode")!)
//        waitForExpectations(timeout: 60, handler: nil)
//
//        XCTAssertNotNil(FRUser.currentUser)
//        XCTAssertNotNil(FRUser.currentUser?.token)
//    }
//
//
//    func test_06_login_safari_vc_validate_auth_code_no_auth_code() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with SFSafariViewController type of Browser object
//
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//        Browser.currentBrowser = browser
//
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let oauth2Error = error as? OAuth2Error {
//                switch oauth2Error {
//                case .unknown:
//                    break
//                default:
//                    XCTFail("While expecting OAuth2Error.unknown; failed with different error \(oauth2Error.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting OAuth2Error.unknown; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        let _ = Browser.validateBrowserLogin(url: URL(string: "frauth://com.forgerock.ios/login")!)
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_07_login_safari_vc_cancelled() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with SFSafariViewController type of Browser object
//
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, vc)
//        Browser.currentBrowser = browser
//
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let browserError = error as? BrowserError {
//                switch browserError {
//                case .externalUserAgentCancelled:
//                    break
//                default:
//                    XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(browserError.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        browser.cancel()
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_08_login_auth_session_cancelled() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with Authentication Framework type of Browser object
//
//        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
//        var topVC = keyWindow?.rootViewController
//        while let presentedViewController = topVC?.presentedViewController {
//            topVC = presentedViewController
//        }
//
//        guard let vc = topVC else {
//            XCTFail("Failed to retrieve top most ViewController")
//            return
//        }
//
//        let browser = Browser(.authSession, oAuth2Client, keychainManager, vc)
//        Browser.currentBrowser = browser
//
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let browserError = error as? BrowserError {
//                switch browserError {
//                case .externalUserAgentCancelled:
//                    break
//                default:
//                    XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(browserError.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        browser.cancel()
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_09_login_native_browser_cancelled() {
//
//        //  TODO: - Temporarily disable this test due to UI issue
////        //  Start SDK
////        self.startSDK()
////
////        //  Construct Browser
////        guard let oAuth2Client = self.config.oAuth2Client, let sessionManager = self.config.sessionManager else {
////            XCTFail("Failed to retrieve OAuth2Client, and/or SessionManager instance after SDK init")
////            return
////        }
////
////        //  Given with SFSafariViewController type of Browser object
////        let browser = Browser(.nativeBrowserApp, oAuth2Client, sessionManager, UIViewController())
////        Browser.currentBrowser = browser
////
////        let ex = self.expectation(description: "Browser Login")
////        browser.login { (user, error) in
////            XCTAssertNil(user)
////            XCTAssertNotNil(error)
////
////            if let browserError = error as? BrowserError {
////                switch browserError {
////                case .externalUserAgentCancelled:
////                    break
////                default:
////                    XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(browserError.localizedDescription)")
////                    break
////                }
////            }
////            else {
////                XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(error?.localizedDescription ?? "")")
////            }
////
////            ex.fulfill()
////        }
////        browser.cancel()
////        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_10_cancel_while_not_in_progress() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Given with SFSafariViewController type of Browser object
//        let browser = Browser(.sfViewController, oAuth2Client, keychainManager, UIViewController())
//
//        //  Try
//        browser.cancel()
//
//        //  Then, try cancel while in progress
//        let ex = self.expectation(description: "Browser Login")
//        browser.login { (user, error) in
//            XCTAssertNil(user)
//            XCTAssertNotNil(error)
//
//            if let browserError = error as? BrowserError {
//                switch browserError {
//                case .externalUserAgentCancelled:
//                    break
//                default:
//                    XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(browserError.localizedDescription)")
//                    break
//                }
//            }
//            else {
//                XCTFail("While expecting BrowserError.externalUserAgentCancelled; failed with different error \(error?.localizedDescription ?? "")")
//            }
//
//            ex.fulfill()
//        }
//        browser.cancel()
//        waitForExpectations(timeout: 60, handler: nil)
//    }
//
//
//    func test_11_build_authorize_request() {
//
//        //  Start SDK
//        self.startSDK()
//
//        //  Construct Browser
//        guard let oAuth2Client = self.config.oAuth2Client, let keychainManager = self.config.keychainManager else {
//            XCTFail("Failed to retrieve OAuth2Client, and/or KeychainManager instance after SDK init")
//            return
//        }
//
//        //  Givne
//        let browser = BrowserBuilder(oAuth2Client, keychainManager).set(browserType: .authSession).setCustomParam(key: "key1", value: "value1").setCustomParam(key: "prompt", value: "login").build()
//        let authorizeURL = browser.buildAuthorizeRequestURL()
//
//        //  Then
//        XCTAssertNotNil(authorizeURL)
//        XCTAssertNotNil(authorizeURL?.absoluteString)
//        //  Validate custom URL query params
//        XCTAssertNotNil(authorizeURL?.valueOf("key1"))
//        XCTAssertEqual(authorizeURL?.valueOf("key1"), "value1")
//        XCTAssertNotNil(authorizeURL?.valueOf("prompt"))
//        XCTAssertEqual(authorizeURL?.valueOf("prompt"), "login")
//        //  Validate PKCE
//        XCTAssertNotNil(authorizeURL?.valueOf("state"))
//        XCTAssertEqual(authorizeURL?.valueOf("state"), browser.pkce.state)
//        XCTAssertNotNil(authorizeURL?.valueOf("code_challenge"))
//        XCTAssertEqual(authorizeURL?.valueOf("code_challenge"), browser.pkce.codeChallenge)
//        XCTAssertNotNil(authorizeURL?.valueOf("code_challenge_method"))
//        XCTAssertEqual(authorizeURL?.valueOf("code_challenge_method"), browser.pkce.codeChallengeMethod)
//        //  Validate OAuth2 client information
//        XCTAssertNotNil(authorizeURL?.valueOf("redirect_uri"))
//        XCTAssertEqual(authorizeURL?.valueOf("redirect_uri"), oAuth2Client.redirectUri.absoluteString)
//        XCTAssertNotNil(authorizeURL?.valueOf("client_id"))
//        XCTAssertEqual(authorizeURL?.valueOf("client_id"), oAuth2Client.clientId)
//        XCTAssertNotNil(authorizeURL?.valueOf("scope"))
//        XCTAssertEqual(authorizeURL?.valueOf("scope"), oAuth2Client.scope)
//        XCTAssertNotNil(authorizeURL?.valueOf("response_type"))
//        XCTAssertEqual(authorizeURL?.valueOf("response_type"), "code")
//    }
//
//
//    func test_12_should_manual_cleanup() {
//        self.shouldCleanup = true
//    }
//}
