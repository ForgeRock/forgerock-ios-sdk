//
//  PingOneProtectEvaluationCallbackTests.swift
//  PingProtectTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import PingProtect
@testable import FRAuth

final class PingOneProtectEvaluationCallbackTests: FRAuthBaseTest {
    
    func getJsonString(pauseBehavioralDataKey: String = "pauseBehavioralData",
                       pauseBehavioralData: String = "true",
                       signalsKey: String = "IDToken1signals",
                       signals: String = "",
                       clientErrorKey: String = "IDToken1clientError",
                       clientError: String = "") -> String {
        let jsonStr = """
        {
          "type": "PingOneProtectEvaluationCallback",
          "output": [
            {
              "name": "\(pauseBehavioralDataKey)",
              "value": \(pauseBehavioralData)
            }
          ],
          "input": [
            {
              "name": "\(signalsKey)",
              "value": "\(signals)"
            },
            {
              "name": "\(clientErrorKey)",
              "value": "\(clientError)"
            }
          ]
        }
        """
        return jsonStr
    }
    
    
    func test_01_basic_init() {
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_callback_construction_successful() {
        let pauseBehavioralData = "false"
        let signalsKey = "IDToken1signals"
        let clientErrorKey = "IDToken1clientError"
        
        let jsonStr = getJsonString(pauseBehavioralData: pauseBehavioralData,
                                    signalsKey: signalsKey,
                                    clientErrorKey: clientErrorKey)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try PingOneProtectEvaluationCallback(json: callbackResponse)
            
            XCTAssertNotNil(callback)
            XCTAssertEqual(String(callback.pauseBehavioralData), pauseBehavioralData)
            
            XCTAssertTrue(callback.inputNames.contains(signalsKey))
            XCTAssertTrue(callback.inputNames.contains(clientErrorKey))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_missing_pauseBehavioralData_value() {
        let jsonStr = getJsonString(pauseBehavioralDataKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectEvaluationCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing pauseBehavioralData")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_04_missing_signalsKey_value() {
        let jsonStr = getJsonString(signalsKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTFail("Initializing PingOneProtectEvaluationCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing signalsKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_05_missing_clientErrorKey_value() {
        let jsonStr = getJsonString(clientErrorKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTFail("Initializing PingOneProtectEvaluationCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing clientErrorKey")
            default:
                XCTFail("Failed with unexpected error: \(error)")
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_06_validate_building_response() {
        let signals = "Signals"
        let clientError = "ClientError"
        
        let jsonStrWithoutInputValues = getJsonString()
        let jsonStrWithInputValues = getJsonString(signals: signals,
                                                   clientError: clientError)
        let callbackResponse1 = self.parseStringToDictionary(jsonStrWithoutInputValues)
        let callbackResponse2 = self.parseStringToDictionary(jsonStrWithInputValues)
        
        do {
            let callback1 = try PingOneProtectEvaluationCallback(json: callbackResponse1)
            XCTAssertNotNil(callback1)
            
            callback1.setSignals(signals)
            callback1.setClientError(clientError)
            
            let response1 = callback1.buildResponse()
            
            XCTAssertTrue(response1["type"] as! String == callbackResponse2["type"] as! String)
            
            let input1 = (response1["input"]  as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            let input2 = (callbackResponse2["input"] as! [[String : String]]).sorted{$0["name"]! > $1["name"]!}
            XCTAssertTrue(input1 == input2)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse1)")
        }
    }
    
    
    func test_07_getSignals_success_with_initialization() {
        
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let ex = self.expectation(description: "SDK initialized")
            PIProtect.start { error in
                XCTAssertNil(error)
                ex.fulfill()
            }
            
            waitForExpectations(timeout: 60, handler: nil)
            
            let expectation = self.expectation(description: "PingOne Protect get signal")
            callback.getData { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 1)
                case .failure(let error):
                    XCTFail("Callback get data failed: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
}
