//
//  FRUserTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class FRUserTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    // MARK: - FRUser Initialization
    
    func test_00_00_BasicFRUserCreation() {
        guard let tokenData = self.readDataFromJSON("AccessToken"), let tokenNoRefreshData = self.readDataFromJSON("AccessTokenNoRefresh") else {
            XCTFail("Failed to read 'AccessToken.json' or 'AccessTokenNoRefresh.json' for \(String(describing: self)) testing")
            return
        }
        
        guard let at = AccessToken(tokenResponse: tokenData), let atNoRefresh = AccessToken(tokenResponse: tokenNoRefreshData) else {
            XCTFail("Failed to construct AccessToken objects from 'AccessToken.json', and/or 'AccessTokenNoRefresh.json'")
            return
        }
        
        let user = FRUser(token: at)
        let user2 = FRUser(token: atNoRefresh)
        
        XCTAssertNotNil(user)
        XCTAssertNotNil(user2)
    }
    
    
    // MARK: - FRUser.login
    
    func test_00_01_FRUserLogin() {
        
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
    
    func test_00_02_FRUserLoginAfterAlreadyLoggedIn() {
        
        // Start SDK
        self.startSDK()
        
        // Perform login first
        self.performLogin()
        
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
        
        let user = FRUser(token: at)
        
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
        self.performLogin()
        
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
        self.performLogin()
        
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
        //  TODO: Removing birthday attribute validation as Cloud Device farm's devices apparently have some issue on translating this Date object; needs further investigation on the issue, and adjustment
//        if let bday = mockUserInfo["birthdate"] as? String {
//            XCTAssertTrue(userDescription.contains(bday))
//        }
        if let zone = mockUserInfo["zoneinfo"] as? String {
            XCTAssertTrue(userDescription.contains(zone))
        }
        if let locale = mockUserInfo["locale"] as? String {
            XCTAssertTrue(userDescription.contains(locale))
        }
    }
    
    
    func test_02_04_UserInfo_Expired_RefreshToken_Renewal_Successful() {
        
        // Perform login first
        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Refresh_Success", "OAuth2_UserInfo_Success"])
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        at1.expiresIn = 0
        if let keychainManager = self.config.keychainManager {
            let _ = try? keychainManager.setAccessToken(token: at1)
        }
        
        let ex = self.expectation(description: "Get User Info")
        FRUser.currentUser?.getUserInfo(completion: { (userInfo, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(userInfo)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        if let lastRequest = FRBaseTestCase.internalRequestsHistory.last {
            XCTAssertTrue(lastRequest.headers.keys.contains("Authorization"))
        }
        else {
            XCTFail("Failed to fatch request history")
        }
    }
    
    
    func test_02_05_UserInfo_Expired_Tokens_Renewal_Failure() {
        
        // Perform login first
        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Load mock responses for refresh token
        self.loadMockResponses(["OAuth2_Token_Failure_InvalidGrant", "OAuth2_AuthorizeRedirect_Failure", "OAuth2_UserInfo_Failure"])
        
        // Persist original AccessToken
        // Manually update token lifetime to force token refresh
        guard let at1 = user.token else {
            XCTFail("Failed to fetch AccessToken")
            return
        }
        
        at1.expiresIn = 0
        if let keychainManager = self.config.keychainManager {
            let _ = try? keychainManager.setAccessToken(token: at1)
        }
        
        let ex = self.expectation(description: "Get User Info")
        FRUser.currentUser?.getUserInfo(completion: { (userInfo, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(userInfo)
            ex.fulfill()
        })
        waitForExpectations(timeout: 60, handler: nil)
        
        if let lastRequest = FRBaseTestCase.internalRequestsHistory.last {
            //  User session/token expired, /userinfo request shouldn't inject Authorization header
            XCTAssertFalse(lastRequest.headers.keys.contains("Authorization"))
            XCTAssertFalse(lastRequest.headers.keys.contains("authorization"))
        }
        else {
            XCTFail("Failed to fatch request history")
        }
    }
    
    
    // MARK: - User Logout
    
    func test_03_01_UserLogoutFailOnAMAPI() {
        // Perform login first
        self.performLogin()
        
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
        self.performLogin()
        
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
        self.performLogin()
        
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
        let user = FRUser(token: at)
        
        // Then
        user.logout()
    }
    
    
    
    // MARK: - currentUser / SDK State
    
    func test_04_00_CurrentUserShouldBeNilBeforeSDKInit() {
        XCTAssertNil(FRUser.currentUser)
    }
    
    
    func test_04_01_LoginToPersistCurrentUser() {
        
        // Perform login first
        self.performLogin()
        
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
    
    func test_05_01_RevokeAccessTokenSuccess() {
        
        // Perform login first
        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Validate if FRUser.currentUser is not nil
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(user.token)
        
        self.loadMockResponses(["OAuth2_Token_Revoke_Success"])
        
        let ex = self.expectation(description: "Revoke AccessToken success")
        user.revokeAccessToken { (updatedUser, error) in
            XCTAssertNotNil(updatedUser)
            XCTAssertNil(error)
            XCTAssertNil(updatedUser?.token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func test_05_02_RevokeAccessTokenError() {
        // Perform login first
        self.performLogin()
        
        guard let user = FRUser.currentUser else {
            XCTFail("Failed to perform user login")
            return
        }
        
        // Validate if FRUser.currentUser is not nil
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(user.token)
        
        let ex = self.expectation(description: "Revoke AccessToken failure")
        user.revokeAccessToken { (updatedUser, error) in
            XCTAssertNotNil(updatedUser)
            XCTAssertNil(updatedUser?.token)
            XCTAssertNotNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
    }
}
