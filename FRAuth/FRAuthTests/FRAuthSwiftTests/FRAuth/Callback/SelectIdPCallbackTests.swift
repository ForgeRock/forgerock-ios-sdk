// 
//  SelectIdPCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class SelectIdPCallbackTests: FRAuthBaseTest {

    
    func test_01_basic_init() {
        let jsonStr = """
        {
            "type": "SelectIdPCallback",
            "output": [
                {
                    "name": "providers",
                    "value": [
                        {
                            "provider": "google",
                            "uiConfig": {
                                "buttonImage": "images/g-logo.png",
                                "buttonClass": "",
                                "buttonDisplayName": "Google",
                                "iconFontColor": "white",
                                "iconClass": "fa-google",
                                "iconBackground": "#4184f3"
                            }
                        },
                        {
                            "provider": "facebook",
                            "uiConfig": {
                                "buttonImage": "",
                                "buttonClass": "fa-facebook-official",
                                "buttonDisplayName": "Facebook",
                                "iconClass": "fa-facebook",
                                "iconFontColor": "white",
                                "iconBackground": "#3b5998"
                            }
                        },
                        {
                            "provider": "apple",
                            "uiConfig": {
                            }
                        }
                    ]
                },
                {
                    "name": "value",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try SelectIdPCallback(json: callbackResponse)
            XCTAssertEqual(callback.providers.count, 3)
            XCTAssertEqual(callback.getValue() as? String, "")
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    func test_02_validate_provider_information() {
        let jsonStr = """
        {
            "type": "SelectIdPCallback",
            "output": [
                {
                    "name": "providers",
                    "value": [
                        {
                            "provider": "google",
                            "uiConfig": {
                                "buttonImage": "images/g-logo.png",
                                "buttonClass": "",
                                "buttonDisplayName": "Google",
                                "iconFontColor": "white",
                                "iconClass": "fa-google",
                                "iconBackground": "#4184f3",
                                "customKey": "customValue"
                            }
                        },
                        {
                            "provider": "facebook",
                            "uiConfig": {
                                "buttonImage": "",
                                "buttonClass": "fa-facebook-official",
                                "buttonDisplayName": "Facebook",
                                "iconClass": "fa-facebook",
                                "iconFontColor": "white",
                                "iconBackground": "#3b5998"
                            }
                        }
                    ]
                },
                {
                    "name": "value",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try SelectIdPCallback(json: callbackResponse)
            XCTAssertEqual(callback.providers.count, 2)
            XCTAssertEqual(callback.getValue() as? String, "")
            
            guard let provider = callback.providers.first else {
                XCTFail("Failed to get expected IdPValue")
                return
            }
            
            XCTAssertEqual(provider.provider, "google")
            XCTAssertEqual(provider.uiConfig?.keys.count, 7)
            XCTAssertEqual(provider.uiConfig?["buttonImage"], "images/g-logo.png")
            XCTAssertEqual(provider.uiConfig?["buttonClass"], "")
            XCTAssertEqual(provider.uiConfig?["buttonDisplayName"], "Google")
            XCTAssertEqual(provider.uiConfig?["iconFontColor"], "white")
            XCTAssertEqual(provider.uiConfig?["iconClass"], "fa-google")
            XCTAssertEqual(provider.uiConfig?["iconBackground"], "#4184f3")
            XCTAssertEqual(provider.uiConfig?["customKey"], "customValue")
            
            guard let provider2 = callback.providers.last else {
                XCTFail("Failed to get expected IdPValue")
                return
            }
            
            XCTAssertEqual(provider2.provider, "facebook")
            XCTAssertEqual(provider2.uiConfig?.keys.count, 6)
            XCTAssertEqual(provider2.uiConfig?["buttonImage"], "")
            XCTAssertEqual(provider2.uiConfig?["buttonClass"], "fa-facebook-official")
            XCTAssertEqual(provider2.uiConfig?["buttonDisplayName"], "Facebook")
            XCTAssertEqual(provider2.uiConfig?["iconClass"], "fa-facebook")
            XCTAssertEqual(provider2.uiConfig?["iconFontColor"], "white")
            XCTAssertEqual(provider2.uiConfig?["iconBackground"], "#3b5998")
            
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    func test_03_set_provider() {
        let jsonStr = """
        {
            "type": "SelectIdPCallback",
            "output": [
                {
                    "name": "providers",
                    "value": [
                        {
                            "provider": "google",
                            "uiConfig": {
                                "buttonImage": "images/g-logo.png",
                                "buttonClass": "",
                                "buttonDisplayName": "Google",
                                "iconFontColor": "white",
                                "iconClass": "fa-google",
                                "iconBackground": "#4184f3"
                            }
                        },
                        {
                            "provider": "facebook",
                            "uiConfig": {
                                "buttonImage": "",
                                "buttonClass": "fa-facebook-official",
                                "buttonDisplayName": "Facebook",
                                "iconClass": "fa-facebook",
                                "iconFontColor": "white",
                                "iconBackground": "#3b5998"
                            }
                        },
                        {
                            "provider": "apple",
                            "uiConfig": {
                            }
                        }
                    ]
                },
                {
                    "name": "value",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let callback = try SelectIdPCallback(json: callbackResponse)
            XCTAssertEqual(callback.providers.count, 3)
            XCTAssertEqual(callback.getValue() as? String, "")
            
            //  Get IdPValue
            let google = callback.providers[0]
            let facebook = callback.providers[1]
            let apple = callback.providers[2]
            
            //  Validate IdPValue
            XCTAssertNotNil(google)
            XCTAssertEqual(google.provider, "google")
            XCTAssertNotNil(facebook)
            XCTAssertEqual(facebook.provider, "facebook")
            XCTAssertNotNil(apple)
            XCTAssertEqual(apple.provider, "apple")
            
            //  Set Google provider, and validate
            callback.setProvider(provider: google)
            var response = callback.buildResponse()
            
            var inputs = response["input"] as? [[String: String]]
            var input = inputs?.first
            var inputName = input?["name"]
            var inputValue = input?["value"]
            
            XCTAssertEqual(inputName, "IDToken1")
            XCTAssertEqual(inputValue, "google")
            
            //  Set Facebook provider, and validate
            callback.setProvider(provider: facebook)
            response = callback.buildResponse()
            
            inputs = response["input"] as? [[String: String]]
            input = inputs?.first
            inputName = input?["name"]
            inputValue = input?["value"]
            
            XCTAssertEqual(inputName, "IDToken1")
            XCTAssertEqual(inputValue, "facebook")
            
            //  Set Apple provider, and validate
            callback.setProvider(provider: apple)
            response = callback.buildResponse()
            
            inputs = response["input"] as? [[String: String]]
            input = inputs?.first
            inputName = input?["name"]
            inputValue = input?["value"]
            
            XCTAssertEqual(inputName, "IDToken1")
            XCTAssertEqual(inputValue, "apple")
            
            // Then
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_04_missing_provider_attribut() {
        let jsonStr = """
        {
            "type": "SelectIdPCallback",
            "output": [
                {
                    "name": "providers",
                    "value": [
                        {
                            "uiConfig": {
                                "buttonImage": "images/g-logo.png",
                                "buttonClass": "",
                                "buttonDisplayName": "Google",
                                "iconFontColor": "white",
                                "iconClass": "fa-google",
                                "iconBackground": "#4184f3"
                            }
                        },
                        {
                            "provider": "facebook",
                            "uiConfig": {
                                "buttonImage": "",
                                "buttonClass": "fa-facebook-official",
                                "buttonDisplayName": "Facebook",
                                "iconClass": "fa-facebook",
                                "iconFontColor": "white",
                                "iconBackground": "#3b5998"
                            }
                        },
                        {
                            "provider": "apple",
                            "uiConfig": {
                            }
                        }
                    ]
                },
                {
                    "name": "value",
                    "value": ""
                }
            ],
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // When
        do {
            let _ = try SelectIdPCallback(json: callbackResponse)
            XCTFail("Initiating SelectIdPCallback with invalid JSON was successful while expecting failure")
        }
        catch let error as AuthError {
            // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing provider attribute")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
}
