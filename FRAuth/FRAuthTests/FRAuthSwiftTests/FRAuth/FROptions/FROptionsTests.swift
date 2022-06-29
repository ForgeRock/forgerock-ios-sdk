// 
//  FROptionsTests.swift
//  FRAuthTests
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
import FRCore

class FROptionsTests: FRAuthBaseTest {
    
    override func setUp() {
        //leave empty
    }
    
    func testDynamicConfigSessionOnly() {
        do {
            let options = FROptions(url: "https://openam-forgerock-sdks/am",
                                    realm: "alpha",
                                    cookieName: "CookieName")
            
            self.dictionaryMatches(options: options)
            
            try FRAuth.start(options: options)
            
            XCTAssertTrue(options.authServiceName == "Login")
            XCTAssertTrue(options.registrationServiceName == "Registration")
            XCTAssertTrue(options.enableCookie)
            XCTAssertTrue(options.cookieName == "CookieName")
            XCTAssertTrue(options.realm == "alpha")
            XCTAssertTrue(options.url == "https://openam-forgerock-sdks/am")
            XCTAssertNil(options.oauthClientId)
            XCTAssertNil(options.oauthRedirectUri)
            XCTAssertNil(options.oauthScope)
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testDynamicConfigBasicOAuth() {
        do {
            let options = FROptions(url: "https://openam-forgerock-sdks/am",
                                    realm: "alpha",
                                    authServiceName: "Login",
                                    registrationServiceName: "Register",
                                    oauthClientId: "iosClient",
                                    oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                    oauthScope: "openid profile email address")
            
            self.dictionaryMatches(options: options)
            
            try FRAuth.start(options: options)
            
            XCTAssertTrue(options.authServiceName == "Login")
            XCTAssertTrue(options.registrationServiceName == "Register")
            XCTAssertTrue(options.enableCookie)
            XCTAssertTrue(options.cookieName == "iPlanetDirectoryPro")
            XCTAssertTrue(options.realm == "alpha")
            XCTAssertTrue(options.url == "https://openam-forgerock-sdks/am")
            XCTAssertTrue(options.oauthClientId == "iosClient")
            XCTAssertTrue(options.oauthRedirectUri == "frauth://com.forgerock.ios.frexample")
            XCTAssertTrue(options.oauthScope == "openid profile email address")
            
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
            self.frAuthInternalValuesCheck(updatedOptions: options)
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testDynamicConfigComplete() {
        do {
            let options = FROptions(url: "https://openam-forgerock-sdks/", realm: "alpha", enableCookie: true, cookieName: "CookieName", timeout: "35", authenticateEndpoint: "json/authenticate", authorizeEndpoint: "json/authorize", tokenEndpoint: "json/accessToken", revokeEndpoint: "json/revoke", userinfoEndpoint: "json/userinfo", sessionEndpoint: "json/session", authServiceName: "LoginTest", registrationServiceName: "RegisterTest", oauthThreshold: "62", oauthClientId: "iOSClient", oauthRedirectUri: "frauth://com.forgerock.ios.frexample", oauthScope: "openid profile email address", keychainAccessGroup: "com.forgerock.ios.FRTestHost", sslPinningPublicKeyHashes: ["hash1", "hash2"])
            
            
            self.dictionaryMatches(options: options)
            
            try FRAuth.start(options: options)
            
            XCTAssertTrue(options.enableCookie)
            XCTAssertTrue(options.cookieName == "CookieName")
            XCTAssertTrue(options.realm == "alpha")
            XCTAssertTrue(options.url == "https://openam-forgerock-sdks/")
            XCTAssertTrue(options.enableCookie == true)
            XCTAssertTrue(options.timeout == "35")
            XCTAssertTrue(options.authenticateEndpoint == "json/authenticate")
            XCTAssertTrue(options.authorizeEndpoint == "json/authorize")
            XCTAssertTrue(options.tokenEndpoint == "json/accessToken")
            XCTAssertTrue(options.revokeEndpoint == "json/revoke")
            XCTAssertTrue(options.userinfoEndpoint == "json/userinfo")
            XCTAssertTrue(options.sessionEndpoint == "json/session")
            XCTAssertTrue(options.authServiceName == "LoginTest")
            XCTAssertTrue(options.registrationServiceName == "RegisterTest")
            XCTAssertTrue(options.oauthThreshold == "62")
            XCTAssertTrue(options.oauthClientId == "iOSClient")
            XCTAssertTrue(options.oauthRedirectUri == "frauth://com.forgerock.ios.frexample")
            XCTAssertTrue(options.oauthScope == "openid profile email address")
            XCTAssertTrue(options.keychainAccessGroup == "com.forgerock.ios.FRTestHost")
            XCTAssertTrue(options.sslPinningPublicKeyHashes?[0] == "hash1")
            XCTAssertTrue(options.sslPinningPublicKeyHashes?[1] == "hash2")
            
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
            self.frAuthInternalValuesCheck(updatedOptions: options)
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testMultipleStarts() {
        do {
            let options = FROptions(url: "https://openam-forgerock-sdks/am",
                                    realm: "alpha",
                                    authServiceName: "Login",
                                    registrationServiceName: "Register",
                                    oauthClientId: "iosClient",
                                    oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                    oauthScope: "openid profile email address")
            
            self.dictionaryMatches(options: options)
            
            try FRAuth.start(options: options)
            
            let frAuth = FRAuth.shared
            XCTAssertNotNil(frAuth)
            
            self.dictionaryMatches(options: frAuth!.options!)
            self.frAuthInternalValuesCheck(updatedOptions: options)
            
            let updatedOptions = FROptions(url: "https://sdkapp.example.com/", realm: "alpha", enableCookie: false, cookieName: "CookieName", timeout: "35", authenticateEndpoint: "json/authenticate", authorizeEndpoint: "json/authorize", tokenEndpoint: "json/accessToken", revokeEndpoint: "json/revoke", userinfoEndpoint: "json/userinfo", sessionEndpoint: "json/session", authServiceName: "LoginTest", registrationServiceName: "RegisterTest", oauthThreshold: "62", oauthClientId: "iOSClient", oauthRedirectUri: "frauth://com.forgerock.ios", oauthScope: "openid email address", keychainAccessGroup: "com.forgerock.ios.FRTestHost", sslPinningPublicKeyHashes: ["hash1", "hash2"])
            
            self.dictionaryMatches(options: updatedOptions)
            try FRAuth.start(options: updatedOptions)
    
            XCTAssertNotNil(frAuth)
            self.dictionaryMatches(options: frAuth!.options!)
            self.frAuthInternalValuesCheck(updatedOptions: updatedOptions)
            
        }
        catch {
            print(error)
            XCTFail()
        }
    }
    
    func testFROptionsComparisons() {
        let optionsA = FROptions(url: "https://openam-forgerock-sdks/am",
                                realm: "alpha",
                                authServiceName: "Login",
                                registrationServiceName: "Register",
                                oauthClientId: "iosClient",
                                oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                oauthScope: "openid profile email address")
        
        let optionsB = FROptions(url: "https://openam-forgerock-sdks/am",
                                realm: "alpha",
                                authServiceName: "Login",
                                registrationServiceName: "Register",
                                oauthClientId: "iosClient",
                                oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                oauthScope: "openid profile email address")
        
        let optionsC = FROptions(url: "https://sdkapp.example.com/", realm: "alpha", enableCookie: false, cookieName: "CookieName", timeout: "35", authenticateEndpoint: "json/authenticate", authorizeEndpoint: "json/authorize", tokenEndpoint: "json/accessToken", revokeEndpoint: "json/revoke", userinfoEndpoint: "json/userinfo", sessionEndpoint: "json/session", authServiceName: "LoginTest", registrationServiceName: "RegisterTest", oauthThreshold: "62", oauthClientId: "iOSClient", oauthRedirectUri: "frauth://com.forgerock.ios", oauthScope: "openid email address", keychainAccessGroup: "com.forgerock.ios.FRTestHost", sslPinningPublicKeyHashes: ["hash1", "hash2"])
        
        XCTAssertTrue(optionsA == optionsB)
        XCTAssertFalse(optionsA == optionsC)
        XCTAssertFalse(optionsB == optionsC)
    }
    
    func testInitWithConfig() {
        let optionsA = FROptions(url: "https://openam-forgerock-sdks/am",
                                realm: "alpha",
                                authServiceName: "Login",
                                registrationServiceName: "Register",
                                oauthClientId: "iosClient",
                                oauthRedirectUri: "frauth://com.forgerock.ios.frexample",
                                oauthScope: "openid profile email address")
        
        let config = try? optionsA.asDictionary()
        XCTAssertNotNil(config)
        let optionsB = FROptions(config: config!)
        XCTAssertTrue(optionsA == optionsB)
    }
    
    //Helper Methods
    private func dictionaryMatches(options: FROptions) {
        let optionsDict = options.optionsDictionary()
        XCTAssertNotNil(optionsDict)
        
        XCTAssertTrue(options.enableCookie == optionsDict?["forgerock_enable_cookie"] as! Bool)
        XCTAssertTrue(options.cookieName == optionsDict?["forgerock_cookie_name"] as! String)
        XCTAssertTrue(options.realm == optionsDict?["forgerock_realm"] as! String)
        XCTAssertTrue(options.url == optionsDict?["forgerock_url"] as! String)
        XCTAssertTrue(options.timeout == optionsDict?["forgerock_timeout"] as! String)
        XCTAssertTrue(options.authenticateEndpoint == optionsDict?["forgerock_authenticate_endpoint"] as? String)
        XCTAssertTrue(options.authorizeEndpoint == optionsDict?["forgerock_authorize_endpoint"] as? String)
        XCTAssertTrue(options.tokenEndpoint == optionsDict?["forgerock_token_endpoint"] as? String)
        XCTAssertTrue(options.revokeEndpoint == optionsDict?["forgerock_revoke_endpoint"] as? String)
        XCTAssertTrue(options.sessionEndpoint == optionsDict?["forgerock_session_endpoint"] as? String)
        XCTAssertTrue(options.authServiceName == optionsDict?["forgerock_auth_service_name"] as! String)
        XCTAssertTrue(options.registrationServiceName == optionsDict?["forgerock_registration_service_name"] as! String)
        XCTAssertTrue(options.oauthThreshold == optionsDict?["forgerock_oauth_threshold"] as? String)
        XCTAssertTrue(options.oauthClientId == optionsDict?["forgerock_oauth_client_id"] as? String)
        XCTAssertTrue(options.oauthRedirectUri == optionsDict?["forgerock_oauth_redirect_uri"] as? String)
        XCTAssertTrue(options.oauthScope == optionsDict?["forgerock_oauth_scope"] as? String)
        XCTAssertTrue(options.keychainAccessGroup == optionsDict?["forgerock_keychain_access_group"] as? String)
        XCTAssertTrue(options.sslPinningPublicKeyHashes == optionsDict?["forgerock_ssl_pinning_public_key_hashes"] as? [String])
    }
    
    private func frAuthInternalValuesCheck(updatedOptions: FROptions) {
        let frAuth = FRAuth.shared
        XCTAssertEqual(frAuth?.authServiceName , updatedOptions.authServiceName)
        XCTAssertEqual(frAuth?.registerServiceName , updatedOptions.registrationServiceName)
        XCTAssertEqual(frAuth?.serverConfig.realm , updatedOptions.realm)
        XCTAssertEqual(frAuth?.serverConfig.baseURL.absoluteString , updatedOptions.url)
        if let userInfoEndpoint = updatedOptions.userinfoEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.userInfoURL , ("\(updatedOptions.url)\(userInfoEndpoint)"))
        }
        if let tokenEndpoint = updatedOptions.tokenEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.tokenURL , ("\(updatedOptions.url)\(tokenEndpoint)"))
        }
        if let sessionEndpoint = updatedOptions.sessionEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.sessionURL , ("\(updatedOptions.url)\(sessionEndpoint)"))
        }
        if let revokeEndpoint = updatedOptions.revokeEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.tokenRevokeURL , ("\(updatedOptions.url)\(revokeEndpoint)"))
        }
        if let authorizeEndpoint = updatedOptions.authorizeEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.authorizeURL , ("\(updatedOptions.url)\(authorizeEndpoint)"))
        }
        if let authenticateEndpoint = updatedOptions.authenticateEndpoint {
            XCTAssertEqual(frAuth?.serverConfig.authenticateURL , ("\(updatedOptions.url)\(authenticateEndpoint)"))
        }
        XCTAssertEqual(frAuth?.serverConfig.cookieName , updatedOptions.cookieName)
        XCTAssertEqual(frAuth?.serverConfig.enableCookie , updatedOptions.enableCookie)
        XCTAssertEqual(frAuth?.serverConfig.timeout , Double(updatedOptions.timeout))
        XCTAssertEqual(frAuth?.oAuth2Client?.scope , updatedOptions.oauthScope)
        XCTAssertEqual(frAuth?.oAuth2Client?.redirectUri.absoluteString , updatedOptions.oauthRedirectUri)
        XCTAssertEqual(frAuth?.oAuth2Client?.clientId , updatedOptions.oauthClientId)
        XCTAssertEqual(frAuth?.oAuth2Client?.threshold , Int(updatedOptions.oauthThreshold ?? "60"))
        XCTAssertNotNil(frAuth?.tokenManager)
        if let team = KeychainService.getAppleTeamId(), let accessGroup = updatedOptions.keychainAccessGroup {
            XCTAssertEqual(frAuth?.keychainManager.accessGroup ,("\(team).\(accessGroup)"))
        } else {
            XCTAssertNil(frAuth?.keychainManager.accessGroup)
            XCTAssertNil(updatedOptions.keychainAccessGroup)
        }
        
    }
}
