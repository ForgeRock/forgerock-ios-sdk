//
//  FRUserTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class FRUserTests: FRBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    // MARK: - FRUser Initialization
    
    func testBasicFRUserCreation() {
        guard let tokenData = self.readDataFromJSON("AccessToken"), let tokenNoRefreshData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessToken.json' or 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData), let atNoRefresh = AccessToken(tokenResponse: tokenNoRefreshData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessToken.json', and/or 'AccessTokenNoRefresh.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        let user = FRUser(token: at, serverConfig: serverConfig)
        let user2 = FRUser(token: atNoRefresh, serverConfig: serverConfig)
        
        XCTAssertNotNil(user)
        XCTAssertNotNil(user2)
    }
    
    
    // MARK: - FRUser.login
    
    func test_FRUserLogin() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        var currentNode: Node?
                        let _ = FRDevice.currentDevice
        // Initiate FRUser.login
        var ex = self.expectation(description: "FRUser.login after SDK start")
        FRUser.login { (user, node, error) in
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let firstNode = currentNode else {
            XCTFail("Failed to perform login: Node was returned as nil")
            return
        }
        
        // Provide input value for callbacks
        for callback in firstNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        firstNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_FRUserLoginAfterAlreadyLoggedIn() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performUserLogin()
        
        guard let initialCurrentUser = FRUser.currentUser else {
            XCTFail("Failed to login before test start")
            return
        }
        
        let ex = self.expectation(description: "FRUser.login after already logged-in")
        FRUser.login { (user, node, error) in
            XCTAssertNil(user)
            XCTAssertNil(node)
            XCTAssertNotNil(error)
            
            if let authError = error as? AuthError {
                switch authError {
                case .userAlreadyAuthenticated:
                    break
                default:
                    XCTFail("While expecting AuthError.userAlreadyAuthenticated; failed with different error \(authError.localizedDescription)")
                    break
                }
            }
            else {
                XCTFail("While expecting AuthError.userAlreadyAuthenticated; failed with different error \(String(describing: error?.localizedDescription))")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertEqual(initialCurrentUser, FRUser.currentUser)
    }
    
    // MARK: - Token Refresh
    
    func test_01_01_FRUserRefreshSessionSyncSuccess() {
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performUserLogin()
        
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
    
    func test_01_02_FRUserRefreshSessionAsyncSuccess() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performUserLogin()
        
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
    
    
    func test_01_03_FRUserRefreshSessionAsyncFailureNoRefreshToken() {
        
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
                switch tokenError {
                case .nullRefreshToken:
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
    
    func test_01_04_FRUserRefreshSessionSyncFailureNoRefreshToken() {
        
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
                switch tokenError {
                case .nullRefreshToken:
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
    
    
    func test_01_05_FRUserRefreshTokenSyncNoToken() {
    
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
    
    
    func test_01_05_FRUserRefreshTokenAsyncNoToken() {
        
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
    
    // MARK: - Get UserInfo
    
    func test_02_01_GetUserInfoFailure() {
        
        // Load mock responses for failure response of /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Failure"])
        
        // Create fake FRUser object for invalid request for /userinfo
        guard let tokenData = self.readDataFromJSON("AccessToken") else {
            XCTFail("Failed to read 'AccessToken.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessToken.json'")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        let user = FRUser(token: at, serverConfig: serverConfig)
        
        let ex = self.expectation(description: "Get User Info")
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(userInfo)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_02_02_GetUserInfoSuccess() {
        // Perform login first
        self.performUserLogin()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Request for UserInfo of currentUser
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
    }
    
    
    func test_02_03_UserInfoObjAndDescription() {
        
        guard self.shouldLoadMockResponses else {
            // No point of testing pre-loaded userInfo for real server
            return
        }
        
        // Perform login first
        self.performUserLogin()
        
        // Load mock responses for retrieving UserInfo from /userinfo
        self.loadMockResponses(["OAuth2_UserInfo_Success"])
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Request for UserInfo of currentUser
        var currentUserInfo: UserInfo?
        let ex = self.expectation(description: "Get User Info")
        user.getUserInfo { (userInfo, error) in
            XCTAssertNotNil(userInfo)
            XCTAssertNil(error)
            currentUserInfo = userInfo
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let mockUserInfo = self.config.userInfo else {
            XCTFail("Failed to load mock userinfo from Config.json")
            return
        }
        
        let userDescription = currentUserInfo!.debugDescription
        
        if let address = mockUserInfo["address"] as? [String: String] {
            
            if let fAddress = address["formatted"] {
                XCTAssertTrue(userDescription.contains(fAddress))
            }
            if let sAddress = address["stree_address"] {
                XCTAssertTrue(userDescription.contains(sAddress))
            }
            if let locality = address["locality"] {
                XCTAssertTrue(userDescription.contains(locality))
            }
            if let region = address["region"] {
                XCTAssertTrue(userDescription.contains(region))
            }
            if let postalCode = address["postal_code"] {
                XCTAssertTrue(userDescription.contains(postalCode))
            }
            if let country = address["country"] {
                XCTAssertTrue(userDescription.contains(country))
            }
        }
        
        if let name = mockUserInfo["name"] as? String {
            XCTAssertTrue(userDescription.contains(name))
        }
        if let fName = mockUserInfo["family_name"] as? String {
            XCTAssertTrue(userDescription.contains(fName))
        }
        if let gName = mockUserInfo["given_name"] as? String {
            XCTAssertTrue(userDescription.contains(gName))
        }
        if let mName = mockUserInfo["middle_name"] as? String {
            XCTAssertTrue(userDescription.contains(mName))
        }
        if let email = mockUserInfo["email"] as? String {
            XCTAssertTrue(userDescription.contains(email))
        }
        if let emailV = mockUserInfo["email_verified"] as? Bool {
            print(String(describing: emailV))
            XCTAssertTrue(userDescription.contains(String(describing: emailV)))
        }
        if let phone = mockUserInfo["phone_number"] as? String {
            XCTAssertTrue(userDescription.contains(phone))
        }
        if let phoneV = mockUserInfo["phone_number_verified"] as? Bool {
            XCTAssertTrue(userDescription.contains(String(describing: phoneV)))
        }
        if let sub = mockUserInfo["sub"] as? String {
            XCTAssertTrue(userDescription.contains(sub))
        }
        if let nName = mockUserInfo["nickname"] as? String {
            XCTAssertTrue(userDescription.contains(nName))
        }
        if let prefUsername = mockUserInfo["preferred_username"] as? String {
            XCTAssertTrue(userDescription.contains(prefUsername))
        }
        if let profile = mockUserInfo["profile"] as? String {
            XCTAssertTrue(userDescription.contains(profile))
        }
        if let picture = mockUserInfo["picture"] as? String {
            XCTAssertTrue(userDescription.contains(picture))
        }
        if let website = mockUserInfo["website"] as? String {
            XCTAssertTrue(userDescription.contains(website))
        }
        if let gender = mockUserInfo["gender"] as? String {
            XCTAssertTrue(userDescription.contains(gender))
        }
        if let bday = mockUserInfo["birthdate"] as? String {
            XCTAssertTrue(userDescription.contains(bday))
        }
        if let zone = mockUserInfo["zoneinfo"] as? String {
            XCTAssertTrue(userDescription.contains(zone))
        }
        if let locale = mockUserInfo["locale"] as? String {
            XCTAssertTrue(userDescription.contains(locale))
        }
    }
    
    
    // MARK: - User Logout
    
    func test_03_01_UserLogoutFailOnAMAPI() {
        // Perform login first
        self.performUserLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Failure",
                                "OAuth2_Token_Revoke_Success",
                                "AuthTree_UsernamePasswordNode"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Validate if FRUser.currentUser is nil
        XCTAssertNil(FRUser.currentUser)
        
        // Validate if AuthService doesn't return stored SSO TOken in the cookie
        let ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: self.config.authServiceName!) { (token: Token?, node, error) in
            
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_03_02_UserLogOutSuccess() {
        
        // Perform login first
        self.performUserLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success",
                                "AuthTree_UsernamePasswordNode"])
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Validate if FRUser.currentUser is nil
        XCTAssertNil(FRUser.currentUser)
        
        // Validate if AuthService doesn't return stored SSO Token in the cookie
        let ex = self.expectation(description: "First Node submit")
        FRUser.login { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    func test_03_03_UserLogOutWithAccessToken() {
        // Perform login first
        self.performUserLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for AM Session revoke, and OAuth2 token revoke
        self.loadMockResponses(["AM_Session_Logout_Success",
                                "OAuth2_Token_Revoke_Success",
                                "AuthTree_UsernamePasswordNode"])
        
        // Given
        user.token?.refreshToken = nil
        
        // Then
        user.logout()
        
        // Sleep for 5 seconds to wait for async logout requests go through
        sleep(5)
        
        // Validate if FRUser.currentUser is nil
        XCTAssertNil(FRUser.currentUser)
        
        // Validate if AuthService doesn't return stored SSO TOken in the cookie
        let ex = self.expectation(description: "First Node submit")
        FRUser.login { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
    }
    
    
    func test_03_04_UserLogOutWithoutSDKInit() {
        
        // This doesn't do anything yet; just to validate it doesn't crash
        // Given
        guard let tokenData = self.readDataFromJSON("AccessToken") else {
            XCTFail("Failed to read 'AccessToken.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessToken.json")
            return
        }
        
        guard let serverConfig = self.config.serverConfig else {
            XCTFail("Failed to load Config for ServerConfig")
            return
        }
        
        // When set currentUser without SSO Token, nor AccessToken
        let user = FRUser(token: at, serverConfig: serverConfig)
        
        // Then
        user.logout()
    }
    
    
    
    // MARK: - currentUser / SDK State
    
    func test_04_00_CurrentUserShouldBeNilBeforeSDKInit() {
        XCTAssertNil(FRUser.currentUser)
    }
    
    
    func test_04_01_LoginToPersistCurrentUser() {
        
        // Perform login first
        self.performUserLogin()
        
        guard let _ = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_04_02_CurrentUserNotNilAfterSDKInit() {
        
        // Given previous test of authenticating, and persisting FRUser
        self.startSDK()
        
        // Then
        XCTAssertNotNil(FRUser.currentUser)
        
        // Should not clean up session for next test
        self.shouldCleanup = false
    }
    
    
    func test_04_03_validate_login_with_existing_session() {
        // Given previous test of authenticating, and persisting FRUser
        self.startSDK()
        
        // Then
        XCTAssertNotNil(FRUser.currentUser)
        
        var loginError: Error?
        
        let ex = self.expectation(description: "First Node submit")
        FRUser.login { (user: FRUser?, node, error) in
            XCTAssertNil(user)
            XCTAssertNil(node)
            XCTAssertNotNil(error)
            loginError = error
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let authError: AuthError = loginError as? AuthError else {
            XCTFail("Unexpected error received: \(String(describing: loginError))")
            return
        }
        
        switch authError {
        case .userAlreadyAuthenticated:
            break
        default:
            XCTFail("Received unexpected error: \(authError)")
            break
        }
    }
    
    
    func test_04_04_user_login_with_no_session() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_NoSession_Success"])
        
        //  noSession interceptor
        FRRequestInterceptorRegistry.shared.registerInterceptors(interceptors: [NoSessionInterceptor()])
        
        XCTAssertNil(FRUser.currentUser)
        
        var currentNode: Node?
        var ex = self.expectation(description: "First Node submit")
        FRUser.login { (user: FRUser?, node, error) in
            
            // Validate result
            XCTAssertNil(user)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (user: FRUser?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(user)
            XCTAssertNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    
    // MARK: - Helper Method
    
    func performUserLogin() {
        
        // Start SDK
        self.config.authServiceName = "UsernamePassword"
        self.startSDK()
        
        // Set mock responses
        self.loadMockResponses(["AuthTree_UsernamePasswordNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        var currentNode: Node?
        
        var ex = self.expectation(description: "First Node submit")
        FRSession.authenticate(authIndexValue: self.config.authServiceName!) { (token: Token?, node, error) in
            
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            return
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(config.username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(config.password)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
}
