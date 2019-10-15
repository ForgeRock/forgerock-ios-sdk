//
//  ServerConfigTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest

class ServerConfigTests: FRBaseTest {

    var serverURL = "http://localhost:8080/am"
    var realm = "customRealm"
    var timeout = 90.0
    
    func testBasicServerConfig() {
        
        // Given
        let serverConfig = ServerConfig(url: URL(string: self.serverURL)!)
        
        // Then
        XCTAssertEqual(serverConfig.treeURL, self.serverURL + "/json/realms/root/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/root/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/root/authorize")
        XCTAssertEqual(serverConfig.timeout, 60.0)
        XCTAssertEqual(serverConfig.realm, "root")
    }
    
    func testServerConfigWithCustomRealm() {
        
        // Given
        let serverConfig = ServerConfig(url: URL(string: self.serverURL)!, realm: self.realm)
        
        // Then
        XCTAssertEqual(serverConfig.treeURL, self.serverURL + "/json/realms/" + self.realm + "/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/" + self.realm + "/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/" + self.realm + "/authorize")
        XCTAssertEqual(serverConfig.timeout, 60.0)
        XCTAssertEqual(serverConfig.realm, self.realm)
    }
    
    
    func testCustomServerConfig() {
        
        // Given
        let serverConfig = ServerConfig(url: URL(string: self.serverURL)!, realm: self.realm, timeout: self.timeout)
        
        // Then
        XCTAssertEqual(serverConfig.treeURL, self.serverURL + "/json/realms/" + self.realm + "/authenticate")
        XCTAssertEqual(serverConfig.tokenURL, self.serverURL + "/oauth2/realms/" + self.realm + "/access_token")
        XCTAssertEqual(serverConfig.authorizeURL, self.serverURL + "/oauth2/realms/" + self.realm + "/authorize")
        XCTAssertEqual(serverConfig.timeout, self.timeout)
        XCTAssertEqual(serverConfig.realm, self.realm)
    }
}
