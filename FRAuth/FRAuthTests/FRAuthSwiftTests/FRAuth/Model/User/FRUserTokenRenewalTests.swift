// 
//  FRUserTokenRenewalTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class FRUserTokenRenewalTests: FRAuthBaseTest {

    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    // MARK: - Token Refresh
    
    func test_01_FRUserRefreshSessionSyncSuccess() {
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        // Validate FRUser.currentUser
        guard var user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            user = try user.getAccessToken()
        }
        catch {
            XCTFail("Token refresh failed: \(error)")
        }
        
        XCTAssertNotEqual(at1, user.token)
    }
    
    func test_02_FRUserRefreshSessionAsyncSuccess() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get User Info")
        user.getAccessToken() { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotEqual(at1, user.token)
    }
    
    
    func test_03_FRUserRefreshSessionAsyncFailureNoRefreshToken() {
        
        // Start SDK
        self.startSDK()
        
        // Create fake FRUser object for invalid request for /userinfo
        guard let tokenData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessTokenNoRefresh.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig, let tokenManager = FRAuth.shared?.tokenManager else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        do {
            // Persist original AccessToken
            // Manually update token lifetime to force token refresh
            at.expiresIn = 0
            try tokenManager.persist(token: at)
        }
        catch {
            XCTFail("Failed to store AccessToken object: \(error.localizedDescription)")
        }
        
        let user = FRUser(token: at, serverConfig: serverConfig)
        
        let ex = self.expectation(description: "Get User Info")
        user.getAccessToken { (user, error) in

            XCTAssertNotNil(error)
            XCTAssertNil(user)
            if let tokenError = error as? TokenError {
                //  This should fail with TokenError.nullToken as it attempts to renew the session using SSO Token, and SSO Token is missing
                switch tokenError {
                case .nullToken:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(tokenError)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(String(describing: error))")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_04_FRUserRefreshSessionSyncFailureNoRefreshToken() {
        
        // Start SDK
        self.startSDK()
        
        // Create fake FRUser object for invalid request for /userinfo
        guard let tokenData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessTokenNoRefresh.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig, let tokenManager = FRAuth.shared?.tokenManager else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        do {
            // Persist original AccessToken
            // Manually update token lifetime to force token refresh
            at.expiresIn = 0
            try tokenManager.persist(token: at)
        }
        catch {
            XCTFail("Failed to store AccessToken object: \(error.localizedDescription)")
        }
        
        var user = FRUser(token: at, serverConfig: serverConfig)
        
        do {
            user = try user.getAccessToken()
        }
        catch {
            if let tokenError = error as? TokenError {
                //  This should fail with TokenError.nullToken as it attempts to renew the session using SSO Token, and SSO Token is missing
                switch tokenError {
                case .nullToken:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(tokenError)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(String(describing: error))")
            }
        }
    }
    
    
    func test_05_FRUserRefreshTokenSyncNoToken() {
    
        // Start SDK
        self.startSDK()
        
        // Create fake FRUser object for invalid request for /userinfo
        guard let tokenData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessTokenNoRefresh.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        // Do not persist token, or user object to test no token from Keychain storage
        var user = FRUser(token: at, serverConfig: serverConfig)
        
        do {
            user = try user.getAccessToken()
        }
        catch {
            if let tokenError = error as? TokenError {
                switch tokenError {
                case .nullToken:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(tokenError)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(String(describing: error))")
            }
        }
    }
    
    
    func test_06_FRUserRefreshTokenAsyncNoToken() {
        
        // Start SDK
        self.startSDK()
        
        // Create fake FRUser object for invalid request for /userinfo
        guard let tokenData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessTokenNoRefresh.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        // Do not persist token, or user object to test no token from Keychain storage
        let user = FRUser(token: at, serverConfig: serverConfig)
        
        let ex = self.expectation(description: "Get User Info")
        user.getAccessToken { (user, error) in
            
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            if let tokenError = error as? TokenError {
                switch tokenError {
                case .nullToken:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(tokenError)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(String(describing: error))")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_07_FRUserGetAccessToken_NoRefreshToken_On_TokenRenewal_Sync() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_No_RefreshToken_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let oldRefreshToken = at1.refreshToken
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.getAccessToken()
            
            XCTAssertNotEqual(at1, newUser.token)
            XCTAssertNotNil(newUser.token?.refreshToken)
            XCTAssertEqual(oldRefreshToken, newUser.token?.refreshToken)
        }
        catch {
            XCTFail("Failed with unexpected error: \(String(describing: error))")
        }
    }
    
    
    func test_08_FRUserGetAccessToken_NoRefreshToken_On_TokenRenewal_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_No_RefreshToken_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let oldRefreshToken = at1.refreshToken
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken() { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotEqual(at1, user.token)
        XCTAssertNotNil(user.token?.refreshToken)
        XCTAssertEqual(oldRefreshToken, user.token?.refreshToken)
    }
    
    
    func test_09_FRUserRefresh_NoRefreshToken_On_TokenRenewal_Sync() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_No_RefreshToken_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let oldRefreshToken = at1.refreshToken
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.refreshSync()
            
            XCTAssertNotEqual(at1, newUser.token)
            XCTAssertNotNil(newUser.token?.refreshToken)
            XCTAssertEqual(oldRefreshToken, newUser.token?.refreshToken)
        }
        catch {
            XCTFail("Failed with unexpected error: \(String(describing: error))")
        }
    }
    
    
    func test_10_FRUserRefresh_NoRefreshToken_On_TokenRenewal_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_No_RefreshToken_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let oldRefreshToken = at1.refreshToken
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.refresh() { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotEqual(at1, user.token)
        XCTAssertNotNil(user.token?.refreshToken)
        XCTAssertEqual(oldRefreshToken, user.token?.refreshToken)
    }
    
    
    //  MARK: - FRUser.getAccessToken Error Handling
    
    func test_11_FRUser_GetAccessToken_RefreshToken_Expired() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with OAuth2Error.invalidGrant, and proceed with authorize flow with SSO token
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_12_FRUser_GetAccessToken_RefreshTokenGrant_InvalidClientError() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidClient"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let oAuth2Error = error as? OAuth2Error {
                switch oAuth2Error {
                case .invalidClient:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(oAuth2Error.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_13_FRUser_GetAccessToken_RefreshTokenGrant_InvalidScope() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidScope"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let oAuth2Error = error as? OAuth2Error {
                switch oAuth2Error {
                case .invalidScope:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(oAuth2Error.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_14_FRUser_GetAccessToken_RefreshToken_SSOToken_Expired_UserAuthenticationRequired() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Failure"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let authError = error as? AuthError {
                switch authError {
                case .userAuthenticationRequired:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(authError.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_15_FRUser_GetAccessToken_RefreshToken_Expired_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with OAuth2Error.invalidGrant, and proceed with authorize flow with SSO token
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.getAccessToken()
            XCTAssertNotNil(newUser)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_16_FRUser_GetAccessToken_RefreshTokenGrant_InvalidClientError_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidClient"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.getAccessToken()
            XCTAssertNil(newUser)
        }
        catch OAuth2Error.invalidClient {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_17_FRUser_GetAccessToken_RefreshTokenGrant_InvalidScope_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidScope"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.getAccessToken()
            XCTAssertNil(newUser)
        }
        catch OAuth2Error.invalidScope {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_18_FRUser_GetAccessToken_RefreshToken_SSOToken_Expired_UserAuthenticationRequired_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Failure"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Expire access_token to enforce refresh_token grant which will fail with other than OAuth2Error.invalidGrant
        at1.expiresIn = 0
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        
        do {
            let newUser = try user.getAccessToken()
            XCTAssertNil(newUser)
        }
        catch AuthError.userAuthenticationRequired {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    //  MARK: - FRUser.refresh Error Handling
    
    func test_19_FRUser_Refresh_RefreshToken_Expired() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        //  FRUser.refresh will enforce token renewl using: 1) refresh_token grant, and 2) /authorize with SSO Token if 1) failed with OAuth2Error.invalidGrant
        let ex = self.expectation(description: "Get Access Token")
        user.refresh { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_20_FRUser_Refresh_RefreshTokenGrant_InvalidClientError() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidClient"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.refresh { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let oAuth2Error = error as? OAuth2Error {
                switch oAuth2Error {
                case .invalidClient:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(oAuth2Error.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_21_FRUser_Refresh_RefreshTokenGrant_InvalidScope() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidScope"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.refresh { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let oAuth2Error = error as? OAuth2Error {
                switch oAuth2Error {
                case .invalidScope:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(oAuth2Error.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_22_FRUser_Refresh_RefreshToken_SSOToken_Expired_UserAuthenticationRequired() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Failure"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.refresh { (user, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(user)
            
            if let authError = error as? AuthError {
                switch authError {
                case .userAuthenticationRequired:
                    break
                default:
                    XCTFail("Failed with unexpected error: \(authError.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("Failed with unexpected error: \(error?.localizedDescription ?? "")")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    

    func test_23_FRUser_Refresh_RefreshToken_Expired_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        //  FRUser.refresh will enforce token renewl using: 1) refresh_token grant, and 2) /authorize with SSO Token if 1) failed with OAuth2Error.invalidGrant
        do {
            let newUser = try user.refreshSync()
            XCTAssertNotNil(newUser)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_24_FRUser_Refresh_RefreshTokenGrant_InvalidClientError_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidClient"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        do {
            let newUser = try user.refreshSync()
            XCTAssertNil(newUser)
        }
        catch OAuth2Error.invalidClient {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_25_FRUser_Refresh_RefreshTokenGrant_InvalidScope_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidScope"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        do {
            let newUser = try user.refreshSync()
            XCTAssertNil(newUser)
        }
        catch OAuth2Error.invalidScope {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_26_FRUser_Refresh_RefreshToken_SSOToken_Expired_UserAuthenticationRequired_Async() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Failure"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        //  Making sure AccessToken exists
        guard user.token != nil else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        
        do {
            let newUser = try user.refreshSync()
            XCTAssertNil(newUser)
        }
        catch AuthError.userAuthenticationRequired {
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    //  MARK: - Token Renewal
    
    func test_27_FRUser_GetAccessToken_SSOToken_Mismatch() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update SSO Token
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Manually change SSO Token associated with AccessToken to invalidate OAuth2 token, and force to go through /authorize flow
        at1.sessionToken = "different_sso_token"
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.getAccessToken { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_28_FRUser_GetAccessToken_SSOToken_Mismatch_Sync() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update SSO Token
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Manually change SSO Token associated with AccessToken to invalidate OAuth2 token, and force to go through /authorize flow
        at1.sessionToken = "different_sso_token"
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.getAccessToken()
            XCTAssertNotNil(newUser)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
    
    func test_29_FRUser_Refresh_SSOToken_Mismatch() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update SSO Token
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Manually change SSO Token associated with AccessToken to invalidate OAuth2 token, and force to go through /authorize flow
        at1.sessionToken = "different_sso_token"
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        let ex = self.expectation(description: "Get Access Token")
        user.refresh { (user, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(user)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_30_FRUser_Refresh_SSOToken_Mismatch_Sync() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Revoke_Success", "OAuth2_AuthorizeRedirect_Success", "OAuth2_Token_Success"])
        
        // Validate FRUser.currentUser
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Persist original AccessToken
        // Manually update SSO Token
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        // Manually change SSO Token associated with AccessToken to invalidate OAuth2 token, and force to go through /authorize flow
        at1.sessionToken = "different_sso_token"
        if let tokenManager = self.config.tokenManager {
            try? tokenManager.persist(token: at1)
        }
        
        do {
            let newUser = try user.refreshSync()
            XCTAssertNotNil(newUser)
        }
        catch {
            XCTFail("Failed with unexpected error: \(error.localizedDescription)")
        }
    }
    
}
