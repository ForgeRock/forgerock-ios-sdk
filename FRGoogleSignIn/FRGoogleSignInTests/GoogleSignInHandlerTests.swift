// 
//  GoogleSignInHandlerTests.swift
//  FRGoogleSignInTests
//
//  Copyright (c) 2021 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import FRGoogleSignIn


class GoogleSignInHandlerTests: XCTestCase {

    func test_01_basic_init() {
        let handler = GoogleSignInHandler()
        XCTAssertNotNil(handler)
        XCTAssertNotNil(handler.tokenType)
        XCTAssertEqual(handler.tokenType, "id_token")
        XCTAssertNotNil(handler.getProviderButtonView())
    }
    
    
    func test_02_default_handler_with_idpcallback() {
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
            XCTAssertNotNil(callback)
            
            let appleHandler = callback.getDefaultIdPHandler(provider: "apple")
            let facebookHandler = callback.getDefaultIdPHandler(provider: "facebook")
            let googleHandler1 = callback.getDefaultIdPHandler(provider: "google")
            let googleHandler2 = callback.getDefaultIdPHandler(provider: "Google")
            let googleHandler3 = callback.getDefaultIdPHandler(provider: "ios-google")
            let googleHandler4 = callback.getDefaultIdPHandler(provider: "google-ios")
            let googleHandler5 = callback.getDefaultIdPHandler(provider: "iosgoogleclient")
            
            XCTAssertNotNil(facebookHandler)
            XCTAssertNotNil(appleHandler)
            XCTAssertNotNil(googleHandler1)
            XCTAssertNotNil(googleHandler2)
            XCTAssertNotNil(googleHandler3)
            XCTAssertNotNil(googleHandler4)
            XCTAssertNotNil(googleHandler5)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}


extension GoogleSignInHandlerTests {
    func parseStringToDictionary(_ str: String) -> [String: Any] {
        var json: [String: Any]?
        if let data = str.data(using: String.Encoding.utf8) {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any]
            } catch {
                XCTFail("Fail to parse JSON payload")
            }
        }
        guard let jsonDict = json else {
            XCTFail("Fail to parse JSON payload")
            return [:]
        }
        return jsonDict
    }
}
