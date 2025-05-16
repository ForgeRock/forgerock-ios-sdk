//
//  PingOneProtectInitializeCallbackTests.swift
//  PingProtectTests
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import PingProtect
@testable import FRCore

final class PingOneProtectInitializeCallbackTests: FRAuthBaseTest {
    
    func getJsonString(envIdKey: String = "envId",
                       envId: String = "02fb4743-189a-4bc7-9d6c-a919edfe6447",
                       consoleLogEnabledKey: String = "consoleLogEnabled",
                       consoleLogEnabled: String = "true",
                       deviceAttributesToIgnoreKey: String = "deviceAttributesToIgnore",
                       deviceAttributesToIgnore: [String] =  [],
                       customHostKey: String = "customHost",
                       customHost: String = "",
                       lazyMetadataKey: String = "lazyMetadata",
                       lazyMetadata: String = "false",
                       behavioralDataCollectionKey: String = "behavioralDataCollection",
                       behavioralDataCollection: String = "true",
                       clientErrorKey: String = "IDToken1clientError",
                       clientError: String = "") -> String {
        let jsonStr = """
        {
          "type": "PingOneProtectInitializeCallback",
          "output": [
            {
              "name": "\(envIdKey)",
              "value": "\(envId)"
            },
            {
              "name": "\(consoleLogEnabledKey)",
              "value": \(consoleLogEnabled)
            },
            {
              "name": "\(deviceAttributesToIgnoreKey)",
              "value": [\(deviceAttributesToIgnore.joined(separator: ","))]
            },
            {
              "name": "\(customHostKey)",
              "value": "\(customHost)"
            },
            {
              "name": "\(lazyMetadataKey)",
              "value": \(lazyMetadata)
            },
            {
              "name": "\(behavioralDataCollectionKey)",
              "value": \(behavioralDataCollection)
            }
          ],
          "input": [
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
            let callback = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_02_callback_construction_successful() {
        let envId = "66fb4743-189a-4bc7-9d6c-a919edfe6466"
        let consoleLogEnabled = "false"
        let deviceAttributesToIgnore: [String] = []
        let customHost = "custom.host"
        let lazyMetadata = "true"
        let behavioralDataCollection = "false"
        let clientErrorKey = "IDToken1clientError"
        
        let jsonStr = getJsonString(envId: envId,
                                    consoleLogEnabled: consoleLogEnabled,
                                    deviceAttributesToIgnore: deviceAttributesToIgnore,
                                    customHost: customHost,
                                    lazyMetadata: lazyMetadata,
                                    behavioralDataCollection: behavioralDataCollection,
                                    clientErrorKey: clientErrorKey)
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try PingOneProtectInitializeCallback(json: callbackResponse)
            
            XCTAssertNotNil(callback)
            XCTAssertEqual(callback.envId, envId)
            XCTAssertEqual(String(callback.consoleLogEnabled), consoleLogEnabled)
            XCTAssertEqual(callback.deviceAttributesToIgnore, deviceAttributesToIgnore)
            XCTAssertEqual(callback.customHost, customHost)
            XCTAssertEqual(String(callback.lazyMetadata), lazyMetadata)
            XCTAssertEqual(String(callback.behavioralDataCollection), behavioralDataCollection)
            
            XCTAssertTrue(callback.inputNames.contains(clientErrorKey))
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_03_missing_envId_value() {
        let jsonStr = getJsonString(envIdKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing envId")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_04_missing_consoleLogEnabled_value() {
        let jsonStr = getJsonString(consoleLogEnabledKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing consoleLogEnabled")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_05_missing_deviceAttributesToIgnore_value() {
        let jsonStr = getJsonString(deviceAttributesToIgnoreKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing deviceAttributesToIgnore")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_06_missing_customHost_value() {
        let jsonStr = getJsonString(customHostKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing customHost")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_07_missing_lazyMetadata_value() {
        let jsonStr = getJsonString(lazyMetadataKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing lazyMetadata")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_08_missing_behavioralDataCollection_value() {
        let jsonStr = getJsonString(behavioralDataCollectionKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initiating PingOneProtectInitializeCallback with invalid JSON was successful")
        }
        catch let error as AuthError {
            switch error {
                // Should only fail with this error
            case .invalidCallbackResponse(let message):
                XCTAssertEqual(message, "Missing behavioralDataCollection")
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func test_09_missing_clientErrorKey_value() {
        let jsonStr = getJsonString(clientErrorKey: "WrongKey")
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let _ = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTFail("Initializing PingOneProtectInitializeCallback with invalid JSON was successful")
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
    
    
    func test_10_validate_building_response() {
        let clientError = "ClientError"
        
        let jsonStrWithoutInputValues = getJsonString()
        let jsonStrWithInputValues = getJsonString(clientError: clientError)
        let callbackResponse1 = self.parseStringToDictionary(jsonStrWithoutInputValues)
        let callbackResponse2 = self.parseStringToDictionary(jsonStrWithInputValues)
        
        do {
            let callback1 = try PingOneProtectInitializeCallback(json: callbackResponse1)
            XCTAssertNotNil(callback1)
            
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
    
    
    func test_11_initialize_success() {
        
        let jsonStr = getJsonString()
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        do {
            let callback = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            
            let expectation = self.expectation(description: "PingOne Protect Initialized")
            callback.start { result in
                switch result {
                case .success:
                    XCTAssertTrue(callback.inputValues.count == 0)
                case .failure(let error):
                    XCTFail("Callback initialize failed: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_12_derived_callback_init() {
        let metaDataJsonString = """
            {
                "type": "MetadataCallback",
                "output": [
                    {
                        "name": "data",
                        "value": {
                            "_type": "PingOneProtect",
                            "_action": "protect_initialize",
                            "envId" : "66fb4743-189a-4bc7-9d6c-a919edfe6466",
                            "consoleLogEnabled" : true,
                            "deviceAttributesToIgnore" : [],
                            "customHost" : "",
                            "lazyMetadata" : true,
                            "behavioralDataCollection" : true,
                            "disableHub" : true,
                            "deviceKeyRsyncIntervals" : 10,
                            "enableTrust" : true,
                            "disableTags" : true
                         }
                    }
                ]
            }
            """
        
        let callbackResponse = self.parseStringToDictionary(metaDataJsonString)
        
        do {
            let callback = try PingOneProtectInitializeCallback(json: callbackResponse)
            XCTAssertNotNil(callback)
            XCTAssertEqual(callback.envId, "66fb4743-189a-4bc7-9d6c-a919edfe6466")
            XCTAssertEqual(callback.consoleLogEnabled, true)
            XCTAssertEqual(callback.deviceAttributesToIgnore, [])
            XCTAssertEqual(callback.customHost, "")
            XCTAssertEqual(callback.lazyMetadata, true)
            XCTAssertEqual(callback.behavioralDataCollection, true)
        }
        catch {
            XCTFail("Failed to construct callback: \(callbackResponse)")
        }
    }
    
    
    func test_13_derived_callback_client_error() {

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
                        "_action": "protect_initialize",
                        "envId": "some_id",
                        "consoleLogEnabled": true,
                        "deviceAttributesToIgnore": [],
                        "customHost": "",
                        "lazyMetadata": true,
                        "behavioralDataCollection": true,
                        "disableHub": true,
                        "deviceKeyRsyncIntervals": 10,
                        "enableTrust": true,
                        "disableTags": true
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
                      "value": "clientError"
                    }
                  ],
                  "input": [
                    {
                      "name": "IDToken1",
                      "value": ""
                    }
                  ]
                }
              ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: "http://localhost:8080/am")!, realm: "customRealm").set(timeout: 90.0).build()
        
        CallbackFactory.shared.registerCallback(callbackType: ProtectCallbackType.initialize.rawValue, callbackClass: PingOneProtectInitializeCallback.self)
        
        do {
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            XCTAssertNotNil(node)
            
            // Expect pingOneProtectInitializeCallback callback
            var pingOneProtectInitializeCallback: PingOneProtectInitializeCallback?
            for callback in node!.callbacks {
                if callback is PingOneProtectInitializeCallback {
                    
                    pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback
                    
                    XCTAssertEqual(pingOneProtectInitializeCallback?.envId, "some_id")
                    XCTAssertEqual(pingOneProtectInitializeCallback?.consoleLogEnabled, true)
                    XCTAssertEqual(pingOneProtectInitializeCallback?.deviceAttributesToIgnore, [])
                    XCTAssertEqual(pingOneProtectInitializeCallback?.customHost, "")
                    XCTAssertEqual(pingOneProtectInitializeCallback?.lazyMetadata, true)
                    XCTAssertEqual(pingOneProtectInitializeCallback?.behavioralDataCollection, true)
                    
                    pingOneProtectInitializeCallback?.setClientError("Some failure!")
                }
            }
            XCTAssertNotNil(pingOneProtectInitializeCallback)
            
            // Expect client error in the HiddenValueCallback
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
