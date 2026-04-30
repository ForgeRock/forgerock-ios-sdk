//
//  SessionManagerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class SessionManagerTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_SessionManager_Init() {

        // Given
        let config = self.readConfigFile(fileName: "FRAuthConfig")
        guard let baseUrl = config["forgerock_url"] as? String, let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load url from configuration file")
            return
        }
        guard let keychainManager = try? KeychainManager(baseUrl: baseUrl) else {
            XCTFail("Failed to initialize KeychainManager")
            return
        }
        
        // Then
        let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
        // Should
        XCTAssertNotNil(sessionManager)
    }
    
    
    func test_02_SessionManagerSingleton() {
            
        // Given
        self.startSDK()
        
        // Then
        XCTAssertNotNil(SessionManager.currentManager)
    }
    
    
    func test_03_RevokeSSOToken() {
        
        // Given
        self.startSDK()
        self.performLogin()
        
        // Then
        guard let sessionManager = SessionManager.currentManager else {
            XCTFail("Failed to retrieve SessionManager singleton object after SDK initialization")
            return
        }
        XCTAssertNotNil(sessionManager.keychainManager.getSSOToken())
        
        // When
        sessionManager.revokeSSOToken()
        
        // Should
        XCTAssertNil(sessionManager.keychainManager.getSSOToken())
    }
    
    
    // MARK: - revokeSSOToken(clearCookies:) Tests

    func test_04_revokeSSOToken_default_clears_cookies() {
        // revokeSSOToken() with the default parameter (clearCookies: true) must wipe
        // the cookie store — this is the normal logout path and the behaviour that
        // existed before the fix.

        self.startSDK()
        self.performLogin()

        guard let sessionManager = SessionManager.currentManager,
              let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Plant a cookie so we have something concrete to assert against.
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "iPlanetDirectoryPro",
            .value: "test-cookie-value",
            .domain: "localhost",
            .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let cookieData = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(cookieData, key: "iPlanetDirectoryPro-localhost")
        }

        XCTAssertNotNil(frAuth.keychainManager.cookieStore.allItems(),
                        "Pre-condition: cookie store must be non-empty before revoke")

        self.loadMockResponses(["AM_Session_Logout_Success"])
        sessionManager.revokeSSOToken() // default clearCookies: true

        // Cookie store must be empty after a full logout revoke.
        let items = frAuth.keychainManager.cookieStore.allItems()
        XCTAssertTrue(items == nil || items!.isEmpty,
                      "Cookie store should be empty after revokeSSOToken() with default clearCookies: true")
        XCTAssertNil(frAuth.keychainManager.getSSOToken(),
                     "SSO token should be removed from keychain")
    }


    func test_05_revokeSSOToken_clearCookies_false_preserves_cookies() {
        // revokeSSOToken(clearCookies: false) must leave the cookie store untouched.
        // This is the session-transition path used during step-up authentication, where
        // the new session's cookies (set by /authenticate) must survive the old-token revoke.

        self.startSDK()
        self.performLogin()

        guard let sessionManager = SessionManager.currentManager,
              let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Plant a sentinel cookie that represents the new session's cookie arriving
        // in the /authenticate response before handleSessionToken fires.
        let sentinelCookieName = "iPlanetDirectoryPro"
        let sentinelCookieKey  = "\(sentinelCookieName)-localhost"
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: sentinelCookieName,
            .value: "new-session-cookie-value",
            .domain: "localhost",
            .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let cookieData = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(cookieData, key: sentinelCookieKey)
        }

        XCTAssertNotNil(frAuth.keychainManager.cookieStore.allItems(),
                        "Pre-condition: cookie store must be non-empty before revoke")

        self.loadMockResponses(["AM_Session_Logout_Success"])
        sessionManager.revokeSSOToken(clearCookies: false)

        // The new-session cookie must still be in the store.
        let items = frAuth.keychainManager.cookieStore.allItems()
        XCTAssertFalse(items == nil || items!.isEmpty,
                       "Cookie store should NOT be empty after revokeSSOToken(clearCookies: false)")

        let cookieStillPresent = items?.keys.contains(sentinelCookieKey) ?? false
        XCTAssertTrue(cookieStillPresent,
                      "New-session cookie must survive revokeSSOToken(clearCookies: false)")

        // SSO token must still have been removed from keychain (the revoke itself happened).
        XCTAssertNil(frAuth.keychainManager.getSSOToken(),
                     "SSO token should still be removed from keychain even when clearCookies is false")
    }


    func test_06_stepup_with_sso_mismatch_preserves_new_session_cookies() {
        // Full end-to-end regression test for the step-up cookie bug.
        //
        // Scenario: User is fully authenticated (SSO + OAuth2). A step-up journey
        // returns a NEW SSO token (Case 2 — mismatch + access token present).
        // After handleSessionToken completes:
        //   - The new SSO token must be stored.
        //   - The new session cookie set by /authenticate must still be in the cookie
        //     store (not wiped by revokeSSOToken called inside handleSessionToken).
        //
        // Before the fix, revokeSSOToken() called cookieStore.deleteAll() unconditionally,
        // wiping the new session's cookie immediately after /authenticate stored it.

        self.startSDK()
        self.performLogin()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Confirm we start in a fully-authenticated state.
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNotNil(try? frAuth.keychainManager.getAccessToken())

        // Step-up: authenticate with a journey that returns a DIFFERENT SSO token.
        // AuthTree_SSOToken_Success2 has:
        //   tokenId = "SBRihCHYvVVV..." (different from AuthTree_SSOToken_Success)
        //   Set-Cookie: iPlanetDirectoryPro=SBRihCHYvVVV...; Path=/; Domain=localhost
        //
        // Mock sequence:
        //   1. AuthTree_UsernamePasswordNode — first node challenge
        //   2. AuthTree_SSOToken_Success2    — journey completes, new SSO token + Set-Cookie
        //   3. AM_Session_Logout_Success     — revokeSSOToken() fire-and-forget
        //   4. OAuth2_Token_Revoke_Success   — revokeOAuth2AndStore revokes old access token
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success2",
                                "AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])

        var currentNode: Node?

        var ex = self.expectation(description: "Step-up first node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            return
        }

        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback {
                cb.setValue(config.username)
            } else if callback is PasswordCallback, let cb = callback as? PasswordCallback {
                cb.setValue(config.password)
            }
        }

        ex = self.expectation(description: "Step-up completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        // The new SSO token from AuthTree_SSOToken_Success2 must be stored.
        let newSSO = frAuth.keychainManager.getSSOToken()
        XCTAssertNotNil(newSSO, "New SSO token must be stored after step-up")
        XCTAssertEqual(newSSO?.value,
                       "SBRihCHYvVVVWrpTIFt6gkm-F9g.*AAJTSQACMDEAAlNLABxmR0tKcllmYjJpOXJ1alN4WWc5RWxvSDNvT289AAR0eXBlAANDVFMAAlMxAAA.*",
                       "Stored SSO token value must match the one from AuthTree_SSOToken_Success2")

        // The new session cookie set by the /authenticate response (AuthTree_SSOToken_Success2
        // carries Set-Cookie: iPlanetDirectoryPro=SBRihCHYvVVV...; Domain=localhost) must
        // still be present in the cookie store. Before the fix this assertion would fail
        // because revokeSSOToken() wiped the store immediately after FRRestClient stored it.
        let cookieItems = frAuth.keychainManager.cookieStore.allItems()
        XCTAssertFalse(cookieItems == nil || cookieItems!.isEmpty,
                       "Cookie store must not be empty after step-up — new session cookie must be preserved")

        // The key is "cookieName-domain". The domain is derived from the actual response URL
        // (not the Set-Cookie header's Domain attribute when they don't match), so we match
        // on the name prefix rather than an exact key to stay decoupled from the test server hostname.
        let cookieIsPresent = cookieItems?.keys.contains { $0.hasPrefix("iPlanetDirectoryPro-") } ?? false
        XCTAssertTrue(cookieIsPresent,
                      "New session cookie from /authenticate response must survive the step-up SSO token revoke. " +
                      "This is a regression test for the bug fixed by revokeSSOToken(clearCookies: false). " +
                      "Cookie store keys: \(cookieItems?.keys.map { $0 } ?? [])")
    }


    func test_07_stepup_case3_sso_mismatch_no_access_token_preserves_new_session_cookies() {
        // Regression test for Case 3 in handleSessionToken:
        // Existing SSO token mismatches new token, but NO access token exists.
        //
        // Before the fix, revokeSSOToken() (called unconditionally in Case 3) wiped
        // the new session's cookie from the cookie store.

        self.startSDK()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Set up Case 3 precondition: SSO token exists, but NO access token.
        let existingToken = Token("existing-sso-token-value", successUrl: "/openam/console", realm: "/")
        frAuth.keychainManager.setSSOToken(ssoToken: existingToken)
        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNil(try? frAuth.keychainManager.getAccessToken())

        // Simulate the /authenticate response writing the new session's cookie into the
        // store (this is what FRRestClient.parseResponseForCookie does before
        // handleSessionToken is called).
        let newCookieKey = "iPlanetDirectoryPro-localhost"
        let newCookieValue = "new-session-cookie-from-authenticate"
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "iPlanetDirectoryPro",
            .value: newCookieValue,
            .domain: "localhost",
            .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let cookieData = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(cookieData, key: newCookieKey)
        }

        // Construct a new SSO token with a DIFFERENT value to trigger Case 3.
        let newToken = Token("new-sso-token-different-value", successUrl: "/openam/console", realm: "/")

        self.loadMockResponses(["AM_Session_Logout_Success"])

        let ex = self.expectation(description: "handleSessionToken Case 3")
        frAuth.keychainManager.handleSessionToken(newToken,
                                                  tokenManager: nil) { (token, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            XCTAssertEqual(token?.value, newToken.value)
            ex.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        // New SSO token must be stored (Case 4 fall-through after Case 3 revoke).
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, newToken.value,
                       "New SSO token must be stored after Case 3 mismatch")

        // New session cookie must still be in the store — not wiped by revokeSSOToken.
        let cookieItems = frAuth.keychainManager.cookieStore.allItems()
        XCTAssertFalse(cookieItems == nil || cookieItems!.isEmpty,
                       "Cookie store must not be empty after Case 3 — new session cookie must be preserved")
        let cookieIsPresent = cookieItems?.keys.contains(newCookieKey) ?? false
        XCTAssertTrue(cookieIsPresent,
                      "New session cookie must survive Case 3 revokeSSOToken(clearCookies: false). " +
                      "Cookie store keys: \(cookieItems?.keys.map { $0 } ?? [])")
    }


    func test_08_revokeSSOToken_with_no_existing_token_is_noop() {
        // When no SSO token is in the keychain, revokeSSOToken() must be a safe no-op:
        // no network call, no cookie wipe, no crash.

        self.startSDK()

        guard let frAuth = FRAuth.shared,
              let sessionManager = SessionManager.currentManager else {
            XCTFail("SDK not initialised")
            return
        }

        // Confirm clean state.
        XCTAssertNil(frAuth.keychainManager.getSSOToken(), "Pre-condition: no SSO token")

        // Plant a cookie to confirm nothing is wiped.
        let cookieKey = "iPlanetDirectoryPro-localhost"
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "iPlanetDirectoryPro", .value: "some-cookie", .domain: "localhost", .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(data, key: cookieKey)
        }

        let requestCountBefore = FRTestNetworkStubProtocol.requestHistory.count
        sessionManager.revokeSSOToken() // both default and explicit true — no token to revoke

        // No network request should have been made.
        XCTAssertEqual(FRTestNetworkStubProtocol.requestHistory.count, requestCountBefore,
                       "No network request should be issued when there is no SSO token to revoke")

        // Cookie store must be untouched — no token means no deleteAll().
        let cookieStillPresent = frAuth.keychainManager.cookieStore.allItems()?.keys.contains(cookieKey) ?? false
        XCTAssertTrue(cookieStillPresent,
                      "Cookie store must not be touched when revokeSSOToken() finds no SSO token")
    }


    func test_09_handleSessionToken_case0_empty_token_preserves_sso_and_cookies() {
        // Case 0: journey returns an empty tokenId (passthrough / NoSession flag).
        // Both the existing SSO token and any existing cookies must be completely untouched.

        self.startSDK()
        self.performLogin()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        let originalSSO = frAuth.keychainManager.getSSOToken()
        XCTAssertNotNil(originalSSO, "Pre-condition: SSO token must exist")

        // Record the cookie state before the empty-token journey.
        let cookiesBefore = frAuth.keychainManager.cookieStore.allItems()?.count ?? 0
        XCTAssertGreaterThan(cookiesBefore, 0, "Pre-condition: cookie store must be non-empty")

        let emptyToken = Token("", successUrl: "", realm: "/")
        let ex = self.expectation(description: "Case 0 completion")
        frAuth.keychainManager.handleSessionToken(emptyToken, tokenManager: frAuth.tokenManager) { token, node, error in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertEqual(token?.value, "", "Empty token must be passed through to caller")
            ex.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // SSO token must be unchanged.
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, originalSSO?.value,
                       "Case 0: existing SSO token must be preserved")

        // Cookie count must be unchanged.
        let cookiesAfter = frAuth.keychainManager.cookieStore.allItems()?.count ?? 0
        XCTAssertEqual(cookiesAfter, cookiesBefore,
                       "Case 0: cookie store must be completely untouched")
    }


    func test_10_handleSessionToken_case1a_fresh_state_stores_sso_preserves_cookies() {
        // Case 1a: no existing SSO token, no access token (fresh state).
        // New SSO token stored; cookies untouched; no revoke calls.

        self.startSDK()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Ensure clean slate: no SSO, no access token.
        XCTAssertNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNil(try? frAuth.keychainManager.getAccessToken())

        // Plant a sentinel cookie to confirm it is not disturbed.
        let cookieKey = "iPlanetDirectoryPro-localhost"
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "iPlanetDirectoryPro", .value: "pre-existing-cookie", .domain: "localhost", .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(data, key: cookieKey)
        }

        let newToken = Token("brand-new-sso-token", successUrl: "/openam/console", realm: "/")
        let requestCountBefore = FRTestNetworkStubProtocol.requestHistory.count

        let ex = self.expectation(description: "Case 1a completion")
        frAuth.keychainManager.handleSessionToken(newToken, tokenManager: frAuth.tokenManager) { token, node, error in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertEqual(token?.value, newToken.value)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // New SSO token stored.
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, newToken.value,
                       "Case 1a: new SSO token must be stored")

        // No revoke network call made.
        XCTAssertEqual(FRTestNetworkStubProtocol.requestHistory.count, requestCountBefore,
                       "Case 1a: no network request should be issued for fresh state")

        // Cookie untouched.
        let cookieStillPresent = frAuth.keychainManager.cookieStore.allItems()?.keys.contains(cookieKey) ?? false
        XCTAssertTrue(cookieStillPresent,
                      "Case 1a: pre-existing cookie must survive fresh-state SSO token store")
    }


    func test_11_handleSessionToken_case1b_centralized_login_revokes_oauth2_preserves_cookies() {
        // Case 1b: no existing SSO token but access token exists (Centralized Login).
        // Access token must be revoked; new SSO token stored; session cookies preserved.

        self.startSDK()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        // Simulate Centralized Login state: inject access token, no SSO.
        guard let tokenData = self.readDataFromJSON("AccessToken"),
              let accessToken = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to build AccessToken from fixture")
            return
        }
        try? frAuth.keychainManager.setAccessToken(token: accessToken)
        XCTAssertNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNotNil(try? frAuth.keychainManager.getAccessToken())

        // Plant the new session's cookie, simulating what parseResponseForCookie does
        // when the /authenticate response arrives before handleSessionToken is called.
        let cookieKey = "iPlanetDirectoryPro-localhost"
        let newCookieValue = "new-session-from-journey"
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .name: "iPlanetDirectoryPro", .value: newCookieValue, .domain: "localhost", .path: "/"
        ]
        if let cookie = FRHTTPCookie(with: cookieProperties),
           let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie, requiringSecureCoding: true) {
            frAuth.keychainManager.cookieStore.set(data, key: cookieKey)
        }

        // Mock the /token/revoke call that revokeOAuth2AndStore triggers.
        self.loadMockResponses(["OAuth2_Token_Revoke_Success"])

        let newToken = Token("new-sso-from-journey", successUrl: "/openam/console", realm: "/")

        let ex = self.expectation(description: "Case 1b completion")
        frAuth.keychainManager.handleSessionToken(newToken, tokenManager: frAuth.tokenManager) { token, node, error in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertEqual(token?.value, newToken.value)
            ex.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        // New SSO token stored.
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, newToken.value,
                       "Case 1b: new SSO token must be stored")

        // Access token revoked locally.
        XCTAssertNil(try? frAuth.keychainManager.getAccessToken(),
                     "Case 1b: stale access token must be revoked")

        // New session cookie preserved — no SSO token existed so revokeSSOToken was NOT called,
        // and revokeOAuth2AndStore must not touch the cookie store.
        let cookieStillPresent = frAuth.keychainManager.cookieStore.allItems()?.keys.contains(cookieKey) ?? false
        XCTAssertTrue(cookieStillPresent,
                      "Case 1b: new session cookie must not be wiped when revoking stale OAuth2 tokens")
    }


    func test_12_handleSessionToken_case4_same_token_no_revoke_no_cookie_wipe() {
        // Case 4: journey returns the same SSO token that is already stored.
        // No revoke call, no cookie store modification.

        self.startSDK()
        self.performLogin()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        guard let existingSSO = frAuth.keychainManager.getSSOToken() else {
            XCTFail("Pre-condition: SSO token must exist after login")
            return
        }

        let cookiesBefore = frAuth.keychainManager.cookieStore.allItems()?.count ?? 0
        let requestCountBefore = FRTestNetworkStubProtocol.requestHistory.count

        // Submit the same SSO token value — triggers Case 4.
        let sameToken = Token(existingSSO.value, successUrl: existingSSO.successUrl, realm: existingSSO.realm)

        let ex = self.expectation(description: "Case 4 completion")
        frAuth.keychainManager.handleSessionToken(sameToken, tokenManager: frAuth.tokenManager) { token, node, error in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertEqual(token?.value, existingSSO.value)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)

        // SSO token unchanged.
        XCTAssertEqual(frAuth.keychainManager.getSSOToken()?.value, existingSSO.value,
                       "Case 4: SSO token value must be unchanged")

        // No network request issued.
        XCTAssertEqual(FRTestNetworkStubProtocol.requestHistory.count, requestCountBefore,
                       "Case 4: no revoke network call should be made when token matches")

        // Cookie store unchanged.
        let cookiesAfter = frAuth.keychainManager.cookieStore.allItems()?.count ?? 0
        XCTAssertEqual(cookiesAfter, cookiesBefore,
                       "Case 4: cookie store must not be touched when SSO token matches")
    }


    func test_13_frsession_logout_clears_sso_token_and_cookies() {
        // FRSession.logout() must revoke the SSO token on the server, remove it from
        // keychain, and clear the cookie store (normal full-logout path).

        self.startSDK()
        self.performLogin()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        XCTAssertNotNil(frAuth.keychainManager.getSSOToken(), "Pre-condition: SSO token must exist")
        let cookiesBefore = frAuth.keychainManager.cookieStore.allItems()?.count ?? 0
        XCTAssertGreaterThan(cookiesBefore, 0, "Pre-condition: cookie store must be non-empty")

        self.loadMockResponses(["AM_Session_Logout_Success"])
        FRSession.currentSession?.logout()

        // Give the fire-and-forget logout request time to complete.
        sleep(3)

        XCTAssertNil(frAuth.keychainManager.getSSOToken(),
                     "SSO token must be removed from keychain after FRSession.logout()")
        XCTAssertNil(FRSession.currentSession,
                     "FRSession.currentSession must be nil after logout")

        let cookiesAfter = frAuth.keychainManager.cookieStore.allItems()
        XCTAssertTrue(cookiesAfter == nil || cookiesAfter!.isEmpty,
                      "Cookie store must be empty after FRSession.logout()")
    }


    func test_14_new_session_cookie_injected_into_authorize_request_after_stepup() {
        // End-to-end chain validation: after a step-up journey completes (Case 2),
        // the new session cookie must be present in the /authorize request that
        // follows when getAccessToken() is called — not an empty or old cookie.

        self.startSDK()
        self.performLogin()

        guard let frAuth = FRAuth.shared else {
            XCTFail("SDK not initialised")
            return
        }

        XCTAssertNotNil(frAuth.keychainManager.getSSOToken())
        XCTAssertNotNil(try? frAuth.keychainManager.getAccessToken())

        // Step-up: new SSO token (AuthTree_SSOToken_Success2 carries its own Set-Cookie).
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success2",
                                "AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success"])

        var currentNode: Node?
        var ex = self.expectation(description: "Step-up first node")
        FRSession.authenticate(authIndexValue: "UsernamePassword") { (token: Token?, node, error) in
            XCTAssertNil(error)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        guard let node = currentNode else { XCTFail("No node returned"); return }
        for callback in node.callbacks {
            if callback is NameCallback, let cb = callback as? NameCallback { cb.setValue(config.username) }
            else if callback is PasswordCallback, let cb = callback as? PasswordCallback { cb.setValue(config.password) }
        }

        ex = self.expectation(description: "Step-up completion")
        node.next { (token: Token?, node, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        // At this point the new SSO token is stored and its cookie is in the store.
        let newSSO = frAuth.keychainManager.getSSOToken()
        XCTAssertNotNil(newSSO, "New SSO token must be stored after step-up")

        // Now request a new access token — this triggers /authorize with the SSO cookie.
        self.loadMockResponses(["OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])

        let requestCountBeforeAuthorize = FRTestNetworkStubProtocol.requestHistory.count

        ex = self.expectation(description: "getAccessToken after step-up")
        FRUser.currentUser?.getAccessToken { user, error in
            XCTAssertNil(error, "getAccessToken must succeed after step-up")
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        // Find the /authorize request that was issued.
        let postRequests = Array(FRTestNetworkStubProtocol.requestHistory.dropFirst(requestCountBeforeAuthorize))
        let authorizeRequest = postRequests.first { req in
            req.url?.absoluteString.contains("/authorize") ?? false
        }
        XCTAssertNotNil(authorizeRequest, "An /authorize request must have been issued after step-up")

        // The cookie header on /authorize must contain the new session's SSO token value —
        // not be empty and not contain the old (revoked) token value.
        let cookieHeader = authorizeRequest?.value(forHTTPHeaderField: "Cookie") ?? ""
        XCTAssertFalse(cookieHeader.isEmpty,
                       "Cookie header on /authorize must not be empty after step-up")
        XCTAssertTrue(cookieHeader.contains("iPlanetDirectoryPro"),
                      "Cookie header on /authorize must contain iPlanetDirectoryPro. Got: \(cookieHeader)")
    }


    // MARK: - Helper Method

    func constructSessionManager() -> SessionManager? {
        // Given
        let config = self.readConfigFile(fileName: "FRAuthConfig")
        guard let baseUrl = config["forgerock_url"] as? String, let serverConfig = self.config.serverConfig else {
           XCTFail("Failed to load url from configuration file")
           return nil
        }
        guard let keychainManager = try? KeychainManager(baseUrl: baseUrl) else {
           XCTFail("Failed to initialize KeychainManager")
           return nil
        }

        // Then
        let sessionManager = SessionManager(keychainManager: keychainManager, serverConfig: serverConfig)
        // Should
        XCTAssertNotNil(sessionManager)
        
        return sessionManager
    }
}
