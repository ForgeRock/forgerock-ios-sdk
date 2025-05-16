//
//  PingOneProtectEvaluationCallbackTests.swift
//  PingProtectTests
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
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
    
    
    func test_08_derived_callback_init() {
        let metaDataJsonString = """
            {
                "type": "MetadataCallback",
                "output": [
                    {
                        "name": "data",
                        "value": {
                            "_type": "PingOneProtect",
                            "_action": "protect_risk_evaluation",
                            "envId" : "some_id",
                            "pauseBehavioralData" : true
                         }
                    }
                ]
            }
            """
        
        let callbackResponse = self.parseStringToDictionary(metaDataJsonString)
        
        do {
            let callback = try PingOneProtectEvaluationCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_09_derived_callback_getSignals_success_with_initialization() {

        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "MetadataCallback",
                    "output": [
                        {
                            "name": "data",
                            "value": {
                                "_type": "PingOneProtect",
                                "_action": "protect_risk_evaluation",
                                "envId" : "some_id",
                                "pauseBehavioralData" : true
                             }
                        }
                    ]
                },
                {
                    "type": "HiddenValueCallback",
                    "output": [
                        {
                            "name": "value",
                            "value": ""
                        },
                        {
                            "name": "id",
                            "value": "pingone_risk_evaluation_signals"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": "pingone_risk_evaluation_signals"
                        }
                    ]
                },
                {
                    "type": "HiddenValueCallback",
                    "output": [
                        {
                            "name": "value",
                            "value": ""
                        },
                        {
                            "name": "id",
                            "value": "clientError"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": "clientError"
                        }
                    ]
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: "http://localhost:8080/am")!, realm: "customRealm").set(timeout: 90.0).build()
        
        CallbackFactory.shared.registerCallback(callbackType: ProtectCallbackType.riskEvaluation.rawValue, callbackClass: PingOneProtectEvaluationCallback.self)
        
        do {
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            XCTAssertNotNil(node)
            
            // Expect PingOneProtectEvaluationCallback callback
            for callback in node!.callbacks {
                if callback is PingOneProtectEvaluationCallback, let pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback {
                    
                    XCTAssertTrue(pingOneProtectEvaluationCallback.pauseBehavioralData)
                    
                    let ex1 = self.expectation(description: "SDK initialized")
                    PIProtect.start { error in
                        XCTAssertNil(error)
                        ex1.fulfill()
                    }
                    
                    var evaulationResult = ""
                    let ex2 = self.expectation(description: "PingOne Protect Evaluate")
                    pingOneProtectEvaluationCallback.getData(completion: { (result) in
                            switch result {
                            case .success:
                                evaulationResult = "Success"
                            case .failure(let error):
                                evaulationResult = error.localizedDescription
                            };
                            ex2.fulfill()
                        })
                    waitForExpectations(timeout: 5, handler: nil)
                    
                    XCTAssertEqual(evaulationResult, "Success")
                    
                    // Ensure that Signals data is not empty after collection
                    var signals: String?
                    for callback in node!.callbacks {
                        if callback is HiddenValueCallback, let hiddenCallback = callback as? HiddenValueCallback, let callbackId = hiddenCallback.id, callbackId.contains(CBConstants.riskEvaluationSignals) {
                            signals = hiddenCallback.getValue() as? String
                        }
                    }
                    XCTAssertNotNil(signals)
                }
            }
        }
        catch {
            XCTFail("Failed to construct node: \(jsonStr)")
        }
    }
    
    
    func test_10_derived_callback_client_error() {
        
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "MetadataCallback",
                    "output": [
                        {
                            "name": "data",
                            "value": {
                                "_type": "PingOneProtect",
                                "_action": "protect_risk_evaluation",
                                "envId" : "some_id",
                                "pauseBehavioralData" : true
                             }
                        }
                    ]
                },
                {
                    "type": "HiddenValueCallback",
                    "output": [
                        {
                            "name": "value",
                            "value": ""
                        },
                        {
                            "name": "id",
                            "value": "pingone_risk_evaluation_signals"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": "pingone_risk_evaluation_signals"
                        }
                    ]
                },
                {
                    "type": "HiddenValueCallback",
                    "output": [
                        {
                            "name": "value",
                            "value": ""
                        },
                        {
                            "name": "id",
                            "value": "clientError"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": "clientError"
                        }
                    ]
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: "http://localhost:8080/am")!, realm: "customRealm").set(timeout: 90.0).build()
        
        CallbackFactory.shared.registerCallback(callbackType: ProtectCallbackType.riskEvaluation.rawValue, callbackClass: PingOneProtectEvaluationCallback.self)
        
        do {
            
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            XCTAssertNotNil(node)
            
            // Expect PingOneProtectEvaluationCallback callback
            var pingOneProtectEvaluationCallback: PingOneProtectEvaluationCallback?
            for callback in node!.callbacks {
                if callback is PingOneProtectEvaluationCallback {
                    pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback
                    pingOneProtectEvaluationCallback?.setClientError("Some failure!")
                }
            }
            XCTAssertNotNil(pingOneProtectEvaluationCallback)
            
            var clientError: String?
            for callback in node!.callbacks {
                if callback is HiddenValueCallback, let hiddenCallback = callback as? HiddenValueCallback, let callbackId = hiddenCallback.id, callbackId.contains("clientError") {
                    clientError = hiddenCallback.getValue() as? String
                }
            }
            XCTAssertNotNil(clientError)
            XCTAssertEqual(clientError, "Some failure!")
        }
        catch {
            XCTFail("Failed to construct node: \(jsonStr)")
        }
    }
}
