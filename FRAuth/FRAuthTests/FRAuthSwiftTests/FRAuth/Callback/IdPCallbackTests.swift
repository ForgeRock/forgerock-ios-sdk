// 
//  IdPCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class IdPCallbackTests: FRAuthBaseTest {
    
    func test_01_basic_init() {
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
            XCTAssertNotNil(callback.idpClient)
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_validate_idpclient() {
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
            XCTAssertNotNil(callback.idpClient)
            XCTAssertNil(callback.idpHandler)
            
            let idpClient = callback.idpClient
            XCTAssertEqual(idpClient.provider, "google")
            XCTAssertEqual(idpClient.clientId, "2817293827-9282hfkd8f012jfhd8f01j2hf8s.apps.googleusercontent.com")
            XCTAssertEqual(idpClient.redirectUri, "https://localhost:8443/openam")
            XCTAssertEqual(idpClient.scopes?.count, 3)
            XCTAssertEqual(idpClient.scopes?[0], "openid")
            XCTAssertEqual(idpClient.scopes?[1], "profile")
            XCTAssertEqual(idpClient.scopes?[2], "email")
            XCTAssertEqual(idpClient.nonce, "h2goqta9144lf0cvnapf5uviydbzb7m")
            XCTAssertEqual(idpClient.acrValues?.count, 0)
            XCTAssertEqual(idpClient.request, "")
            XCTAssertEqual(idpClient.requestUri, "")
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_set_token_values() {
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
            XCTAssertNotNil(callback.idpClient)
            XCTAssertNil(callback.idpHandler)
            
            callback.setToken("i71UYQSakI8yBB1WJ0OgmU5P8rSQFkH")
            callback.setTokenType("authorization_code")
            
            let response = callback.buildResponse()
            let inputs = response["input"] as? [[String: String]]
            
            XCTAssertEqual(callback.tokenTypeKey, "IDToken1token_type")
            XCTAssertEqual(callback.tokenKey, "IDToken1token")
            
            for input in inputs ?? [] {
                if let name = input["name"], let value = input["value"] {
                    if name.hasSuffix("_type") {
                        XCTAssertEqual(value, "authorization_code")
                        XCTAssertEqual(name, "IDToken1token_type")
                    }
                    else if name.hasSuffix("token") {
                        XCTAssertEqual(value, "i71UYQSakI8yBB1WJ0OgmU5P8rSQFkH")
                        XCTAssertEqual(name, "IDToken1token")
                    }
                    else {
                        XCTFail("Callback response has unexpected input value")
                    }
                }
                else {
                    XCTFail("Failed to extract inputs value from Callback JSON")
                }
            }
            
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_04_missing_provider_value() {
        let jsonStr = """
        {
            "type": "IdPCallback",
            "output": [
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
        
        //  When
        do {
            let _ = try IdPCallback(json: callbackResponse)
            XCTFail("Initiating IdPCallback with invalid JSON was successful while expecting failure")
        }
        catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing provider value")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_05_missing_client_id_value() {
        let jsonStr = """
        {
            "type": "IdPCallback",
            "output": [
                {
                    "name": "provider",
                    "value": "google"
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
        
        //  When
        do {
            let _ = try IdPCallback(json: callbackResponse)
            XCTFail("Initiating IdPCallback with invalid JSON was successful while expecting failure")
        }
        catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing client_id value")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_06_missing_redirect_uri_value() {
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
        
        //  When
        do {
            let _ = try IdPCallback(json: callbackResponse)
            XCTFail("Initiating IdPCallback with invalid JSON was successful while expecting failure")
        }
        catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing redirect_uri value")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_07_sign_in_without_handler() {
        let jsonStr = """
        {
            "type": "IdPCallback",
            "output": [
                {
                    "name": "provider",
                    "value": "custom"
                },
                {
                    "name": "clientId",
                    "value": "2817293827-9282hfkd8f012jfhd8f01j2hf8s"
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
            
            let ex = self.expectation(description: "IdpCallback.signIn()")
            callback.signIn { (token, tokenType, error) in
                XCTAssertNil(token)
                XCTAssertNil(tokenType)
                XCTAssertNotNil(error)
                
                if let slError = error as? SocialLoginError {
                    switch slError {
                    case .missingIdPHandler:
                        break
                    default:
                        XCTFail("Failed with unexpected error type")
                        break
                    }
                }
                else {
                    XCTFail("Failed with unexpected error type")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
}
