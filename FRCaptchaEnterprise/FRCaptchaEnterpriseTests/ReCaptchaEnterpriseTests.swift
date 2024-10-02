//
//  FRCaptchaEnterpriseTests.swift
//  FRCaptchaEnterpriseTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCaptchaEnterprise
@testable import FRAuth

@available(iOS 13, *)
final class ReCaptchaEnterpriseTests: FRAuthBaseTest {
  
  var mockProvider: MockRecaptchaClientProvider!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    mockProvider = MockRecaptchaClientProvider()
  }
  
  override func tearDownWithError() throws {
    mockProvider = nil
    try super.tearDownWithError()
  }
  
  func getJsonCallback(captchaApiUriKey: String = "captchaApiUri",
                       captchaApiUri: String = "https://recaptchaenterprise.googleapis.com/v1",
                       recaptchaSiteKeyKey: String = "recaptchaSiteKey",
                       recaptchaSiteKey: String = "siteKey",
                       tokenKey: String = "IDToken1token",
                       token: String = "",
                       actionKey: String = "IDToken1action",
                       action: String = "",
                       clientErrorKey: String = "IDToken1clientError",
                       clientError: String = "",
                       payloadKey: String = "IDToken1payload",
                       payload: String = "") -> String {
    let jsonStr = """
        {
          "type": "ReCaptchaEnterpriseCallback",
          "output": [
            {
              "name": "\(recaptchaSiteKeyKey)",
              "value": "\(recaptchaSiteKey)"
            }
          ],
          "input": [
            {
              "name": "\(tokenKey)",
              "value": "\(token)"
            },
            {
              "name": "\(actionKey)",
              "value": "\(action)"
            },
            {
              "name": "\(clientErrorKey)",
              "value": "\(clientError)"
            },
            {
              "name": "\(payloadKey)",
              "value": "\(payload)"
            }
          ]
        }
        """
    return jsonStr
  }
  
  func getInvalidJsonCallback(captchaApiUriKey: String = "captchaApiUri",
                              captchaApiUri: String = "https://recaptchaenterprise.googleapis.com/v1",
                              recaptchaSiteKeyKey: String = "recaptchaSiteKey",
                              recaptchaSiteKey: String = "siteKey",
                              tokenKey: String = "IDToken1token",
                              token: String = "",
                              actionKey: String = "IDToken1action",
                              action: String = "",
                              clientErrorKey: String = "IDToken1clientError",
                              clientError: String = "",
                              payloadKey: String = "IDToken1payload",
                              payload: String = "") -> String {
    let jsonStr = """
        {
          "type": "ReCaptchaEnterpriseCallback",
          "output": [],
          "input": [
            {
              "name": "\(tokenKey)",
              "value": "\(token)"
            },
            {
              "name": "\(actionKey)",
              "value": "\(action)"
            },
            {
              "name": "\(clientErrorKey)",
              "value": "\(clientError)"
            },
            {
              "name": "\(payloadKey)",
              "value": "\(payload)"
            }
          ]
        }
        """
    return jsonStr
  }
  
  func test_01_basic_init() {
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    do {
      let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
      XCTAssertNotNil(callback)
    }
    catch {
      XCTFail("Failed to construct callback: \(callbackResponse)")
    }
  }
  
  func testInitializationFailure() throws {
    
    let jsonStr = getInvalidJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    XCTAssertThrowsError(try ReCaptchaEnterpriseCallback(json: callbackResponse)) { error in
      XCTAssertTrue(error.localizedDescription.contains("Missing recaptchaSiteKey"))
    }
  }
  
  @available(iOS 13.0, *)
  func testExecuteSuccess() async throws {
    // Arrange
    
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    do {
      let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
      
      
      mockProvider.shouldReturnToken = "valid-token"
      
        try await callback.execute(action: "test-action", timeoutInMillis: 15000, recaptchaProvider: mockProvider)
      
      // Verify token
      XCTAssertEqual(callback.inputValues[callback.tokenKey] as? String, "valid-token")
      
      // Verify captured parameters
      XCTAssertEqual(mockProvider.capturedSiteKey, "siteKey")
      XCTAssertEqual(mockProvider.capturedClientTimeout, 15000)
      XCTAssertEqual(mockProvider.capturedAction?.action, "test-action")
    }
    catch {
      XCTFail("Failed to validate captcha")
    }
    
  }
  
  @available(iOS 13.0, *)
  func testExecuteFailureForIntialization() async throws {
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    mockProvider.shouldThrowErrorIntialization = RecaptchaError(domain: "com.google.recaptcha", code: .errorCodeInternalError, message: "INVALID_CAPTCHA_CLIENT")
    
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    do {
      
        try await callback.execute(action: "test-action", timeoutInMillis: 15000, recaptchaProvider: mockProvider)
      XCTFail("Expected error not thrown")
    } catch let error as RecaptchaError {
      XCTAssertEqual(error.errorCode, 100)
      XCTAssertTrue(callback.inputValues[callback.clientErrorKey].debugDescription.contains("com.google.recaptcha error 100"))
    }
    
    // Verify captured parameters
    XCTAssertEqual(mockProvider.capturedSiteKey, "siteKey")
    XCTAssertEqual(mockProvider.capturedAction?.action, nil)
  }
  
  
  @available(iOS 13.0, *)
  func testExecuteFailureForExecution() async throws {
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    mockProvider.shouldthrowError = RecaptchaError(domain: "com.google.recaptcha", code: .errorCodeInternalError, message: "INVALID_CAPTCHA_CLIENT")
    
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    do {
      
        try await callback.execute(action: "test-action", timeoutInMillis: 15000, recaptchaProvider: mockProvider)
      XCTFail("Expected error not thrown")
    } catch let error as RecaptchaError {
      XCTAssertEqual(error.errorCode, 100)
      XCTAssertTrue(callback.inputValues[callback.clientErrorKey].debugDescription.contains("com.google.recaptcha error 100"))
    }
    
    // Verify captured parameters
    XCTAssertEqual(mockProvider.capturedSiteKey, "siteKey")
    XCTAssertEqual(mockProvider.capturedClientTimeout, 15000)
    XCTAssertEqual(mockProvider.capturedAction?.action, "test-action")
  }
  
  @available(iOS 13.0, *)
  func testExecuteFailureForUnknownExecution() async throws {
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    
    mockProvider.shouldthrowError = NSError(domain: "com.google.recaptcha", code: 100, userInfo: nil)
    
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    do {
      
      try await callback.execute(action: "test-action", timeoutInMillis: 15000, recaptchaProvider: mockProvider)
      XCTFail("Expected error not thrown")
    }
    catch let error as NSError  {
      XCTAssertEqual(error.code, 100)
      XCTAssertEqual(callback.inputValues[callback.clientErrorKey] as? String, error.localizedDescription)
    }
    
    // Verify captured parameters
    XCTAssertEqual(mockProvider.capturedSiteKey, "siteKey")
    XCTAssertEqual(mockProvider.capturedClientTimeout, 15000)
    XCTAssertEqual(mockProvider.capturedAction?.action, "test-action")
  }
  
  
  @available(iOS 13.0, *)
  func testExecuteTokenIsNil() async throws {
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    mockProvider.shouldReturnToken = nil
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    do {
        try await callback.execute(action: "test-action", timeoutInMillis: 15000, recaptchaProvider: mockProvider)
      XCTFail("Expected error not thrown")
    } catch {
      XCTAssertTrue(callback.inputValues[callback.clientErrorKey].debugDescription.contains("INVALID_CAPTCHA_TOKEN"))
    }
    
    // Verify captured parameters
    XCTAssertEqual(mockProvider.capturedSiteKey, "siteKey")
    XCTAssertEqual(mockProvider.capturedClientTimeout, 15000)
    XCTAssertEqual(mockProvider.capturedAction?.action, "test-action")
  }
  
  // Test the JSONStringify function
  func testAdditionalJson() async throws {
    
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    
    // Test case 1: Set valid JSON payload
    let validJson: [String: Any] = ["key": "value"]
    callback.setPayload(validJson)
    XCTAssertTrue((callback.inputValues[callback.payloadKey] as! String).contains("value"))
   
  }
  
  // Test the JSONStringify function
  func testAction() async throws {
    
    let jsonStr = getJsonCallback()
    let callbackResponse = self.parseStringToDictionary(jsonStr)
    let callback = try ReCaptchaEnterpriseCallback(json: callbackResponse)
    
    // Test case 1: Set valid JSON payload
    let action = "login_test"
    callback.setAction(action)
    callback.setClientError("customClientError")
    
    XCTAssertEqual(callback.inputValues[callback.actionKey] as? String, "login_test")
    XCTAssertEqual(callback.inputValues[callback.clientErrorKey] as? String, "customClientError")
  }
  
}

// MARK: - Mock RecaptchaClientProvider
@available(iOS 13, *)
class MockRecaptchaClientProvider: RecaptchaClientProvider {
  var shouldReturnToken: String?
  
  var shouldThrowErrorIntialization: RecaptchaError?
  
  var shouldthrowError: NSError?
  
  // Properties to capture the arguments passed to methods
  var capturedSiteKey: String?
  var capturedClientTimeout: Double?
  var capturedAction: RecaptchaAction?
  
  func fetchClient(withSiteKey siteKey: String) async throws -> RecaptchaClient? {
    
    capturedSiteKey = siteKey
    
    if let error = shouldThrowErrorIntialization {
      throw error
    }
    return nil
  }
  
  func execute(recaptchaClient: RecaptchaClient?, action: RecaptchaAction, timeout: Double) async throws -> String? {
    capturedAction = action
    capturedClientTimeout = timeout
    if let shouldthrowError = shouldthrowError {
      throw shouldthrowError
    }
    return shouldReturnToken
  }
}
