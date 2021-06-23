//
//  ServerConfigTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class ServerConfigTests: FRAuthBaseTest {

    var serverURL = "http://localhost:8080/am"
    var realm = "customRealm"
    var timeout = 90.0
    
    func test_01_default_server_config() {
        
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!).build()
        
        // Then
        XCTAssertEqual(serverConfig.authenticateURL, self.serverURL + "/json/realms/root/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/root/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/root/authorize")
        XCTAssertEqual(serverConfig.userInfoURL, self.serverURL + "/oauth2/realms/root/userinfo")
        XCTAssertEqual(serverConfig.tokenRevokeURL, self.serverURL + "/oauth2/realms/root/token/revoke")
        XCTAssertEqual(serverConfig.sessionURL, self.serverURL + "/json/realms/root/sessions")
        XCTAssertEqual(serverConfig.endSessionURL, self.serverURL + "/oauth2/realms/root/connect/endSession")
        XCTAssertEqual(serverConfig.timeout, 60.0)
        XCTAssertEqual(serverConfig.realm, "root")
        XCTAssertEqual(serverConfig.enableCookie, true)
        XCTAssertEqual(serverConfig.cookieName, OpenAM.iPlanetDirectoryPro)
    }
    
    
    func test_02_custom_realm_server_config() {
        
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).build()
        
        // Then
        XCTAssertEqual(serverConfig.authenticateURL, self.serverURL + "/json/realms/" + self.realm + "/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/" + self.realm + "/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/" + self.realm + "/authorize")
        XCTAssertEqual(serverConfig.userInfoURL, self.serverURL + "/oauth2/realms/" + self.realm + "/userinfo")
        XCTAssertEqual(serverConfig.tokenRevokeURL, self.serverURL + "/oauth2/realms/" + self.realm + "/token/revoke")
        XCTAssertEqual(serverConfig.sessionURL, self.serverURL + "/json/realms/" + self.realm + "/sessions")
        XCTAssertEqual(serverConfig.endSessionURL, self.serverURL + "/oauth2/realms/" + self.realm + "/connect/endSession")
        XCTAssertEqual(serverConfig.timeout, 60.0)
        XCTAssertEqual(serverConfig.realm, self.realm)
        XCTAssertEqual(serverConfig.enableCookie, true)
        XCTAssertEqual(serverConfig.cookieName, OpenAM.iPlanetDirectoryPro)
    }
    
    
    func test_03_custom_timeout_server_config() {
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!).set(timeout: 100.0).build()
        // Then
        XCTAssertEqual(serverConfig.timeout, 100.0)
        XCTAssertEqual(serverConfig.cookieName, OpenAM.iPlanetDirectoryPro)
    }
    
    
    func test_04_custom_enable_cookie_server_config() {
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!).set(enableCookie: false).build()
        // Then
        XCTAssertEqual(serverConfig.enableCookie, false)
        XCTAssertEqual(serverConfig.cookieName, OpenAM.iPlanetDirectoryPro)
    }
    
    
    func test_05_custom_path_server_config() {
        // With
        let builder = ServerConfigBuilder(url: URL(string: self.serverURL)!)
        
        // authenticate path
        var serverConfig = builder.set(authenticatePath: "/custom/authenticate/path").build()
        XCTAssertEqual(serverConfig.authenticateURL, self.serverURL + "/custom/authenticate/path")
        
        // token path
        serverConfig = builder.set(tokenPath: "/custom/token/path").build()
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/custom/token/path")
        
        // authorize path
        serverConfig = builder.set(authorizePath: "/custom/authorize/path").build()
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/custom/authorize/path")
        
        // userinfo path
        serverConfig = builder.set(userInfoPath: "/custom/userinfo").build()
        XCTAssertEqual(serverConfig.userInfoURL, self.serverURL + "/custom/userinfo")
        
        // token revoke path
        serverConfig = builder.set(revokePath: "/custom/token/revoke").build()
        XCTAssertEqual(serverConfig.tokenRevokeURL, self.serverURL + "/custom/token/revoke")
        
        // session path
        serverConfig = builder.set(sessionPath: "/custom/session").build()
        XCTAssertEqual(serverConfig.sessionURL, self.serverURL + "/custom/session")
        
        // endSession path
        serverConfig = builder.set(endSessionPath: "/custom/endSession").build()
        XCTAssertEqual(serverConfig.endSessionURL, self.serverURL + "/custom/endSession")
    }
    
    
    func test_06_custom_nested_server_config() {
        
        // Given
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!).set(enableCookie: false).set(timeout: 120.0).set(authenticatePath: "/custom/authenticate").set(sessionPath: "/custom/session").set(cookieName: "customCookieName").set(endSessionPath: "/custom/endSession").build()

        // Then
        XCTAssertEqual(serverConfig.authenticateURL, self.serverURL + "/custom/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/root/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/root/authorize")
        XCTAssertEqual(serverConfig.userInfoURL, self.serverURL + "/oauth2/realms/root/userinfo")
        XCTAssertEqual(serverConfig.tokenRevokeURL, self.serverURL + "/oauth2/realms/root/token/revoke")
        XCTAssertEqual(serverConfig.sessionURL, self.serverURL + "/custom/session")
        XCTAssertEqual(serverConfig.endSessionURL, self.serverURL + "/custom/endSession")
        XCTAssertEqual(serverConfig.timeout, 120.0)
        XCTAssertEqual(serverConfig.realm, "root")
        XCTAssertEqual(serverConfig.enableCookie, false)
        XCTAssertEqual(serverConfig.cookieName, "customCookieName")
    }
}
