// 
//  AppleSignInHandlerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
import AuthenticationServices
@testable import FRAuth

class AppleSignInHandlerTests: FRAuthBaseTest {
    
    func test_01_basic_init() {
        let handler = AppleSignInHandler()
        XCTAssertNotNil(handler)
        XCTAssertEqual(handler.tokenType, "id_token")
        
        if #available(iOS 13.0, *) {
            XCTAssertNotNil(handler.getProviderButtonView())
        }
        else {
            XCTAssertNil(handler.getProviderButtonView())
        }
    }
    
    
    func test_02_test_default_handler() {
        let jsonStr = """
        {
            "type": "IdPCallback",
            "output": [
                {
                    "name": "provider",
                    "value": "google"
                },
                {
                    "name": "clientId",
                    "value": "2817293827-9282hfkd8f012jfhd8f01j2hf8s.apps.googleusercontent.com"
                },
                {
                    "name": "redirectUri",
                    "value": "https://localhost:8443/openam"
                },
                {
                    "name": "scopes",
                    "value": [
                        "openid",
                        "profile",
                        "email"
                    ]
                },
                {
                    "name": "nonce",
                    "value": "h2goqta9144lf0cvnapf5uviydbzb7m"
                },
                {
                    "name": "acrValues",
                    "value": []
                },
                {
                    "name": "request",
                    "value": ""
                },
                {
                    "name": "requestUri",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1token",
                    "value": ""
                },
                {
                    "name": "IDToken1token_type",
                    "value": ""
                }
            ]
        }
        """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try IdPCallback(json: callbackResponse)
            let googleHandler = callback.getDefaultIdPHandler(provider: "google")
            let facebookHandler = callback.getDefaultIdPHandler(provider: "facebook")
            let appleHandler = callback.getDefaultIdPHandler(provider: "apple")
            let appleHandler2 = callback.getDefaultIdPHandler(provider: "apple-ios")
            let appleHandler3 = callback.getDefaultIdPHandler(provider: "ios-apple")
            let appleHandler4 = callback.getDefaultIdPHandler(provider: "Apple")
            let appleHandler5 = callback.getDefaultIdPHandler(provider: "iosappleclient")
            
            XCTAssertNil(googleHandler)
            XCTAssertNil(facebookHandler)
            XCTAssertNotNil(appleHandler)
            XCTAssertNotNil(appleHandler2)
            XCTAssertNotNil(appleHandler3)
            XCTAssertNotNil(appleHandler4)
            XCTAssertNotNil(appleHandler5)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_authorization_request_nonce() {
    
        //  Execute the test only for iOS 13 and above
        if #available(iOS 13.0, *) {
            let idpClient = IdPClient(provider: "apple", clientId: "com.forgerock.ios.signinwithapple", redirectUri: "frauthtest://", scopes: ["email", "name"], nonce: "h2goqta9144lf0cvnapf5uviydbzb7m32", acrValues: nil, request: nil, requestUri: nil)
            let handler = AppleSignInHandler()
            
            let asRequest = handler.createASAuthorizationRequest(idpClient: idpClient)
            XCTAssertEqual(asRequest.requestedScopes?.count, 2)
            XCTAssertEqual(asRequest.nonce, "h2goqta9144lf0cvnapf5uviydbzb7m32")
        }
    }
    
    
    func test_04_authorization_request_nil_nonce() {
        
        //  Execute the test only for iOS 13 and above
        if #available(iOS 13.0, *) {
            let idpClient = IdPClient(provider: "apple", clientId: "com.forgerock.ios.signinwithapple", redirectUri: "frauthtest://", scopes: ["email", "name", "fullName"], nonce: nil, acrValues: nil, request: nil, requestUri: nil)
            let handler = AppleSignInHandler()
            
            let asRequest = handler.createASAuthorizationRequest(idpClient: idpClient)
            XCTAssertEqual(asRequest.requestedScopes?.count, 3)
            XCTAssertNil(asRequest.nonce)
            XCTAssertTrue(asRequest.requestedScopes?.contains(ASAuthorization.Scope(rawValue: "name")) ?? false)
            XCTAssertTrue(asRequest.requestedScopes?.contains(ASAuthorization.Scope(rawValue: "email")) ?? false)
            XCTAssertTrue(asRequest.requestedScopes?.contains(ASAuthorization.Scope(rawValue: "fullName")) ?? false)
        }
    }
    
    
    func test_05_authorization_request_emtpy_scope() {
        
        //  Execute the test only for iOS 13 and above
        if #available(iOS 13.0, *) {
            let idpClient = IdPClient(provider: "apple", clientId: "com.forgerock.ios.signinwithapple", redirectUri: "frauthtest://", scopes: nil, nonce: nil, acrValues: nil, request: nil, requestUri: nil)
            let handler = AppleSignInHandler()
            
            let asRequest = handler.createASAuthorizationRequest(idpClient: idpClient)
            XCTAssertEqual(asRequest.requestedScopes?.count, 0)
            XCTAssertNil(asRequest.nonce)
            XCTAssertEqual(asRequest.requestedScopes, [])
        }
    }
}
