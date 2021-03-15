//
//  NodeTests.swift
//  FRAuthTests
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

class NodeTests: FRAuthBaseTest {
    
    var serverURL = "http://localhost:8080/am"
    var realm = "customRealm"
    var timeout = 90.0
    var authServiceName = "loginService"
    
    var clientId = "a09a42d7-b2f2-47f2-a3eb-a3c15e8008e8"
    var scope = "openid email phone"
    var redirectUri = "http://redirect.uri"

    func testNodeInit() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": ""
                        }
                    ]
                },
                {
                    "type": "PasswordCallback",
                    "output": [
                        {
                            "name": "prompt","value": "Password"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken3", "value": ""
                        }
                    ],
                    "_id": 2
                },
                {
                    "type": "ChoiceCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "SecondFactorChoice"
                        },
                        {
                            "name": "choices",
                            "value": [
                                "Email",
                                "SMS"
                            ]
                        },
                        {
                            "name": "defaultChoice",
                            "value": 0
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken2",
                            "value": 0
                        }
                    ],
                    "_id": 5
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            
            XCTAssertNotNil(node)
            XCTAssertNotNil(node?.authId)
            XCTAssertEqual(node?.callbacks.count, 3)
            XCTAssertNil(node?.pageHeader)
            XCTAssertNil(node?.pageDescription)
            XCTAssertNil(node?.stage)
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitMissingAuthId() {
        
        // Given
        let jsonStr = """
        {
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
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
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidAuthServiceResponse:
                if !error.localizedDescription.contains("missing or invalid 'authId'") || error.code != 1000009 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitWithInvalidCallback() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
                        }
                    ]
                },
                {
                    "type": "PasswordCallback",
                    "output": [
                        {
                            "name": "noprompt","value": "Password"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken3", "value": ""
                        }
                    ],
                    "_id": 2
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                if error.code != 1000007 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitWithUnsupportedCallback() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": ""
                        }
                    ]
                },
                {
                    "type": "UnsupportedCallback",
                    "output": [
                        {
                            "name": "prompt","value": "Password"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken3", "value": ""
                        }
                    ],
                    "_id": 2
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .unsupportedCallback:
                if !error.localizedDescription.contains("UnsupportedCallback") || error.code != 1000008 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitWithInvalidCallbackWithMissingType() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": ""
                        }
                    ]
                },
                {
                    "output": [
                        {
                            "name": "prompt","value": "Password"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken3", "value": ""
                        }
                    ],
                    "_id": 2
                }
            ]
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidCallbackResponse:
                if error.code != 1000007 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitWithMissingCallbacks() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM"
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidAuthServiceResponse:
                if error.code != 1000009 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    func testNodeInitWithUnexpectedCallbackDataType() {
        
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": "invalid"
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            // If not fail, should fail
            XCTFail("Passed while expecting failure with empty Dictionary, and callback obj: \(node.debugDescription)")
        } catch let error as AuthError { // Catch AuthError
            switch error {
            // Should only fail with this error
            case .invalidAuthServiceResponse:
                if error.code != 1000009 {
                    XCTFail("Failed with unexpected error message: \(error.localizedDescription)")
                }
                break
            default:
                XCTFail("Failed with unexpected error: \(error)")
                break
            }
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
    
    
    func testNodeWithPageHeaderAndDescription() {
        // Given
        let jsonStr = """
        {
            "authId": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoSW5kZXhWYWx1ZSI6IkV4YW1wbGUiLCJvdGsiOiJjOWtvNXQ5Y3JncmdrNTI3MzUxN2RyMXI3YyIsImF1dGhJbmRleFR5cGUiOiJzZXJ2aWNlIiwicmVhbG0iOiIvIiwic2Vzc2lvbklkIjoiKkFBSlRTUUFDTURFQUJIUjVjR1VBQ0VwWFZGOUJWVlJJQUFKVE1RQUEqZXlKMGVYQWlPaUpLVjFRaUxDSmpkSGtpT2lKS1YxUWlMQ0poYkdjaU9pSklVekkxTmlKOS5aWGxLTUdWWVFXbFBhVXBMVmpGUmFVeERTalpoV0VGcFQybEtUMVF3TlVaSmFYZHBXbGMxYWtscWIybFJWRVY1VDBWT1ExRjVNVWxWZWtreFRtbEpjMGx0Um5OYWVVazJTVzFTY0dOcFNqa3VMbGh1VFVSVVJtVlhRMVU0TkRaMllXdG9lRmxoUTFFdVZXRktWazA1ZUVSQ01sQkViRTgwWldwWmJESkVZMXBPWnkxWGJtWnJVelU1UW1SVlQxQlZTbk5tVTB4UFkxZEpWME5HVEdKQ1YzWlNXVmhaTFVkQkxYUmtkM1V3TUcxeFdXVkVlbU0wWlZkcFdXdEtTMmRSV1VoQlpucEZhRVZTU0U4MGJGWkxZalpVVEVnMVJ6VXpTV3RxU0hKQ2EwMUNOMjV0Y25KWk16QlBOMVZLTkVwWlgwWnNjR0pOWldwSlVWUkxhRnBwZFVwaVJsaHdOMDVqYXpOU1FVdGpaMW96VjNScFdpMXdZM1YzUzJkM2NIVkxVRnB2UTJRMFJYVkRRakJmUTBnNGMxODJUMnR1ZEMxM1dVcGtkVEZKU2xobU5UWTBjakowYkd4UmJuaEVZbGRqYlV0V01taFFTVmRKZEZaTE1XSlNPRFI0ZUhNMFVGQkRiblV5VkU0dE1WRnNUazlwWmpsYVJUa3pNV3RETTE5MVRGQnZXVFF0V1VsekxWaFdOVzVUWlRab1F6STJhalUyWlZSbFRYQktja1U0TWpWbGNHZ3pPRXBSVDNCT1VtMTJkVGhQV1ZCTmEwcHdNQzB3VkUxMFIxbFdOamhoWTB0RlkxVjBibmxyVGxWVk4wVkxSa2N0TjFnNFl6VnFSMVV3U2w5YWFUTkZhMk0wT1hWdFFubFRiMms0UWtwTFdtaFdZak50VUZWMlpUSlhlSFZzUzJObVZuTXpTbHBOTlVJek1tTlVTbDloWldsNk9HOXRjRTFwUTB0dE1UUXllalZFTUZWS2FESk9YelkxVFZKR1ZEWnVXSE5mY2w5YWVrRk1aRFZKZERWemJIUkxTVUZEYlVsc01rOXljVlF3ZDNodllXWnFTWGx3V2tNelJEZHZSMmxwY25SeFpuaElNRmxRWDFwVU9FbDRkbHBTVlcxYWFHSlFhVzQwU1hWMFQxUTRPV2wxZEdwd2RYUlpWRmhXTkZoV2NtdFlRVWgyV0hVeFNGTXdWbXh0VG5NNVNWOU5SMjlpVTBoeGVYazBTalY1ZGs1M1pqTklkeTQ1V2pBeVZYazNSMDVUY2xsNGJqaG1Nbk10ZUZabi43SHNDVlNMUUljREk5S1pzQ1N0cjJEM3BTQmJhV1A1UlY2T29pX0lnODA0IiwiZXhwIjoxNTYyNzg4MDAyLCJpYXQiOjE1NjI3ODc3MDJ9.oEiBLxT62uwmz0EtLQxwzjyrgcIy7fpevO6TntEK8aM",
            "callbacks": [
                {
                    "type": "NameCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "User Name"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken1",
                            "value": ""
                        }
                    ]
                },
                {
                    "type": "PasswordCallback",
                    "output": [
                        {
                            "name": "prompt",
                            "value": "Password"
                        }
                    ],
                    "input": [
                        {
                            "name": "IDToken3",
                            "value": ""
                        }
                    ]
                }
            ],
            "header": "This is header",
            "description": "This is description",
            "stage": "This is stage"
        }
        """
        let authServiceResponse = self.parseStringToDictionary(jsonStr)
        let serverConfig = ServerConfigBuilder(url: URL(string: self.serverURL)!, realm: self.realm).set(timeout: self.timeout).build()
        
        do {
            // Then
            let node = try Node(UUID().uuidString, authServiceResponse, serverConfig, "serviceName", "service")
            XCTAssertNotNil(node?.pageHeader)
            XCTAssertNotNil(node?.pageDescription)
            XCTAssertNotNil(node?.stage)
            
            XCTAssertEqual(node?.pageHeader, "This is header")
            XCTAssertEqual(node?.pageDescription, "This is description")
            XCTAssertEqual(node?.stage, "This is stage")
        } catch {
            XCTFail("Failed with unexpected error: \(error)")
        }
    }
}
