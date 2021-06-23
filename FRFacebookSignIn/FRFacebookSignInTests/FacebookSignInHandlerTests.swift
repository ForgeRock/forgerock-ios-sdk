// 
//  FacebookSignInHandlerTests.swift
//  FRFacebookSignInTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth
@testable import FRFacebookSignIn
@testable import FacebookLogin

class FacebookSignInHandlerTests: XCTestCase {

    func test_01_basic_init() {
        let handler = FacebookSignInHandler()
        XCTAssertNotNil(handler)
        XCTAssertNotNil(handler.tokenType)
        XCTAssertEqual(handler.tokenType, "access_token")
        XCTAssertNotNil(handler.getProviderButtonView())
    }
    
    
    func test_02_default_handler_with_idpcallback() {
        let jsonStr = """
        {
            "type": "IdPCallback",
            "output": [
                {
                    "name": "provider",
                    "value": "facebook"
                },
                {
                    "name": "clientId",
                    "value": "28172938279282"
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
            let googleHandler = callback.getDefaultIdPHandler(provider: "google")
            let facebookHandler1 = callback.getDefaultIdPHandler(provider: "facebook")
            let facebookHandler2 = callback.getDefaultIdPHandler(provider: "Facebook")
            let facebookHandler3 = callback.getDefaultIdPHandler(provider: "ios-facebook")
            let facebookHandler4 = callback.getDefaultIdPHandler(provider: "facebook-ios")
            let facebookHandler5 = callback.getDefaultIdPHandler(provider: "iosfacebookclient")
            
            XCTAssertNil(googleHandler)
            XCTAssertNotNil(appleHandler)
            XCTAssertNotNil(facebookHandler1)
            XCTAssertNotNil(facebookHandler2)
            XCTAssertNotNil(facebookHandler3)
            XCTAssertNotNil(facebookHandler4)
            XCTAssertNotNil(facebookHandler5)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}


extension FacebookSignInHandlerTests {
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
