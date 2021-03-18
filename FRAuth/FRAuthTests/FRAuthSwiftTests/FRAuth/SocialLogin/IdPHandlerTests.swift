// 
//  IdPHandlerTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class IdPHandlerTests: FRAuthBaseTest {

    static var error: Error?
    static var tokenTypeValue: String?
    static var tokenValue: String?
    static var customView: UIView?
    
    
    override func tearDown() {
        super.tearDown()
        
        IdPHandlerTests.error = nil
        IdPHandlerTests.tokenTypeValue = nil
        IdPHandlerTests.tokenValue = nil
        IdPHandlerTests.customView = nil
    }
    
    
    func test_01_init_test() {
        let handler = CustomHandler()
        XCTAssertNotNil(handler)
        XCTAssertNil(handler.getProviderButtonView())
        XCTAssertEqual(handler.tokenType, "id_token")
    }
    
    
    func test_02_button_view() {
        
        let view = UITextView()
        IdPHandlerTests.customView = view
        
        let handler = CustomHandler()
        XCTAssertNotNil(handler)
        XCTAssertNotNil(handler.getProviderButtonView())
        XCTAssertEqual(handler.getProviderButtonView(), view)
    }
    
    
    func test_03_sign_in_with_callback() {
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
            XCTAssertNotNil(callback.idpClient)
            let handler = CustomHandler()
            let viewController = UIViewController()
            IdPHandlerTests.tokenValue = "123456"
            IdPHandlerTests.tokenTypeValue = "access_token"
            
            let ex = self.expectation(description: "IdpCallback.signIn()")
            callback.signIn(handler: handler, presentingViewController: viewController) { (token, tokenType, error) in
                XCTAssertNil(error)
                XCTAssertEqual(handler.presentingViewController, viewController)
                XCTAssertEqual(token, "123456")
                XCTAssertEqual(tokenType, "access_token")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            let response = callback.buildResponse()
            let inputs = response["input"] as? [[String: String]]

            for input in inputs ?? [] {
                if let name = input["name"], let value = input["value"] {
                    if name.hasSuffix("_type") {
                        XCTAssertEqual(value, "access_token")
                    }
                    else if name.hasSuffix("token") {
                        XCTAssertEqual(value, "123456")
                    }
                    else {
                        XCTFail("Callback response has unexpected input value")
                    }
                }
                else {
                    XCTFail("Failed to extract inputs value from Callback JSON")
                }
            }
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }    
}

class CustomHandler: IdPHandler {
    var tokenType: String = "id_token"
    var presentingViewController: UIViewController?
    
    func signIn(idpClient: IdPClient, completion: @escaping SocialLoginCompletionCallback) {
        completion(IdPHandlerTests.tokenValue, IdPHandlerTests.tokenTypeValue, IdPHandlerTests.error)
    }
    
    func getProviderButtonView() -> UIView? {
        return IdPHandlerTests.customView
    }
}
