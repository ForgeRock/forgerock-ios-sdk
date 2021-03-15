// 
//  DeviceProfileCallbackTests.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class DeviceProfileCallbackTests: FRAuthBaseTest {
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
    }
    
    
    func test_01_device_profile_init() {
        
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": true
                },
                {
                    "name": "location",
                    "value": true
                },
                {
                    "name": "message",
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
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertTrue(callback.metadataRequired)
            XCTAssertTrue(callback.locationRequired)
            XCTAssertEqual(callback.message.count, 0)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_device_profile_required_none_init() {
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": false
                },
                {
                    "name": "location",
                    "value": false
                },
                {
                    "name": "message",
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
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertFalse(callback.metadataRequired)
            XCTAssertFalse(callback.locationRequired)
            XCTAssertEqual(callback.message.count, 0)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_device_profile_message_init() {
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": true
                },
                {
                    "name": "location",
                    "value": true
                },
                {
                    "name": "message",
                    "value": "testing message"
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
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertTrue(callback.metadataRequired)
            XCTAssertTrue(callback.locationRequired)
            XCTAssertNotNil(callback.message)
            XCTAssertEqual(callback.message, "testing message")
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_04_device_execute() {
        // Start SDK to collect DeviceIdentifier
        startSDK()
        
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": true
                },
                {
                    "name": "location",
                    "value": true
                },
                {
                    "name": "message",
                    "value": "testing message"
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
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertTrue(callback.metadataRequired)
            XCTAssertTrue(callback.locationRequired)
            XCTAssertNotNil(callback.message)
            XCTAssertEqual(callback.message, "testing message")

            let ex = self.expectation(description: "Executing DeviceProfile")
            callback.execute { (result) in
                XCTAssertTrue(result.keys.contains("metadata"))
                XCTAssertTrue(result.keys.contains("identifier"))
                XCTAssertTrue(result.keys.contains("version"))
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_04_device_execute_without_metadata() {
        // Start SDK to collect DeviceIdentifier
        startSDK()
        
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "output": [
                {
                    "name": "metadata",
                    "value": false
                },
                {
                    "name": "location",
                    "value": false
                },
                {
                    "name": "message",
                    "value": "testing message"
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
            let callback = try DeviceProfileCallback(json: callbackResponse)
            
            // Then
            XCTAssertFalse(callback.metadataRequired)
            XCTAssertFalse(callback.locationRequired)
            XCTAssertNotNil(callback.message)
            XCTAssertEqual(callback.message, "testing message")

            let ex = self.expectation(description: "Executing DeviceProfile")
            callback.execute { (result) in
                XCTAssertFalse(result.keys.contains("metadata"))
                XCTAssertTrue(result.keys.contains("identifier"))
                XCTAssertTrue(result.keys.contains("version"))
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_05_no_output_init() {
        // Given
        let jsonStr = """
        {
            "type": "DeviceProfileCallback",
            "input": [
                {
                    "name": "IDToken1",
                    "value": ""
                }
            ]
        }
        """
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        // Then
        do {
            let _ = try DeviceProfileCallback(json: callbackResponse)
            XCTFail("Failed to validate missing output section; succeed while expecting failure: \(callbackResponse)")
        }
        catch {
        }
    }
}
