//
//  AA_09_PingOneProtectInitializeCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import RecaptchaEnterprise
import FRCaptchaEnterprise

@available(iOS 13, *)
class AA_12_ReCaptchaEnterpriseCallbackTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    static var SITE_KEY: String = "6Lc0NUIqAAAAALRSrhXb5CWrZPzWkezBFB_0mnqS" // this is configured in the test joruney
    
    let options = FROptions(url: "https://openam-recaptcha.forgeblocks.com/am",
                            realm: "alpha",
                            enableCookie: true,
                            cookieName: "b431aeda2ba0e98",
                            timeout: "180",
                            authServiceName: "TEST-e2e-recaptcha-enterprise",
                            oauthThreshold: "60",
                            oauthClientId: "iosclient",
                            oauthRedirectUri: "http://localhost:8081",
                            oauthScope: "openid profile email address",
                            keychainAccessGroup: "com.bitbar.*"
                            )

    override func setUp() {
        do {
            try FRAuth.start(options: options)
        }
        catch {
            XCTFail("Fail to start the the SDK with custom config.")
        }
    }
    
    override func tearDown() {
        FRSession.currentSession?.logout()
        super.tearDown()
    }
    
    func test_01_recaptcha_enterprise_success() async throws {
        var currentNode: Node
        
        do {
            try currentNode = await startTest(nodeConfiguration: "success")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a ReCaptchaEnterprise node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        var tokenResult = "" // Used to verify that AM uses the same token acquired by the SDK
        // We expect ReCaptchaEnterpriseCallback callback here...
        for callback in currentNode.callbacks {
            if callback is ReCaptchaEnterpriseCallback, let reCaptchaEnterpriseCallback = callback as? ReCaptchaEnterpriseCallback {
                XCTAssertEqual(reCaptchaEnterpriseCallback.recaptchaSiteKey, AA_12_ReCaptchaEnterpriseCallbackTest.SITE_KEY)
                do {
                    try await reCaptchaEnterpriseCallback.execute()
                    XCTAssertNotNil(reCaptchaEnterpriseCallback.inputValues[reCaptchaEnterpriseCallback.tokenKey] as? String)
                    XCTAssertNotNil(reCaptchaEnterpriseCallback.tokenResult)
                    tokenResult = reCaptchaEnterpriseCallback.tokenResult // We are going to configure later that the same token is used in AM
                }
                catch let error as RecaptchaError {
                    XCTFail("reCaptchaEnterpriseCallback.execute() failed: \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit ReCaptchaEnterpriseCallback callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        // Confirm that reCAPTCHA Enterprise node execution is successulf.
        // Note: Upon success the test tree returns CaptchaEnterpriseNode.ASSESSMENT_RESULT in a TextOutput callback...
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                let assessmentData = Data(textOutputCallback.message.utf8)
                
                do {
                    if let assessmentDictionary = try JSONSerialization.jsonObject(with: assessmentData, options: []) as? [String: Any] {
                        // Assert a few things in the assessment data:
                        let event = assessmentDictionary["event"] as! [String: Any]
                        let tokenProperties = assessmentDictionary["tokenProperties"] as! [String: Any]
                        let riskAnalysis = assessmentDictionary["riskAnalysis"] as! [String: Any]
                        
                        let userAgent = event["userAgent"] as! String // e.g: "FRTestHost/1 CFNetwork/1406.0.4 Darwin/23.6.0"
                        let siteKey = event["siteKey"] as! String // Should be the one configured in the ReCaptcha node
                        let userIpAddress = event["userIpAddress"] as! String
                        let token = event["token"] as! String
                        let action = tokenProperties["action"] as! String // should be "login" by default
                        let valid = tokenProperties["valid"] as! Bool // should be valid
                        let iosBundleId = tokenProperties["iosBundleId"] as! String // should be "com.forgerock.FRTestHost"
                        let score = riskAnalysis["score"] as! Double
                        
                        XCTAssertEqual(siteKey, AA_12_ReCaptchaEnterpriseCallbackTest.SITE_KEY)
                        XCTAssert(userAgent.contains("Darwin"))
                        XCTAssert(!userIpAddress.isEmpty)
                        XCTAssertEqual(token, tokenResult)
                        XCTAssertEqual(action, "login")
                        XCTAssertTrue(valid)
                        XCTAssertEqual(iosBundleId, "com.forgerock.FRTestHost")
                        XCTAssertGreaterThanOrEqual(score, 0.0)
                        XCTAssertLessThanOrEqual(score, 1.0)
                   }
                } catch let error as NSError {
                    XCTFail("Error parsing the assessment data \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the TextOutput callback and continue with the flow")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        /// At the end the user should be logged in
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_recaptcha_enterprise_success_custom() async throws {
        var currentNode: Node
        
        do {
            try currentNode = await startTest(nodeConfiguration: "success")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a ReCaptchaEnterprise node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect ReCaptchaEnterpriseCallback callback here...
        for callback in currentNode.callbacks {
            if callback is ReCaptchaEnterpriseCallback, let reCaptchaEnterpriseCallback = callback as? ReCaptchaEnterpriseCallback {
                do {
                    // Set additional payload and custom action
                    reCaptchaEnterpriseCallback.setPayload(["firewallPolicyEvaluation": false,
                                                                   "express": false,
                                                                   "transaction_data": [
                                                                        "transaction_id": "custom-payload-1234567890",
                                                                        "payment_method": "credit-card",
                                                                        "card_bin": "1111",
                                                                        "card_last_four": "1234",
                                                                        "currency_code": "CAD"
                                                                        ],
                                                                  ])
                    try await reCaptchaEnterpriseCallback.execute(action: "custom_action")
                }
                catch let error as RecaptchaError {
                    XCTFail("reCaptchaEnterpriseCallback.execute() failed: \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit ReCaptchaEnterpriseCallback callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        // Confirm that reCAPTCHA Enterprise node execution is successulf.
        // Note: Upon success the test tree returns CaptchaEnterpriseNode.ASSESSMENT_RESULT in a TextOutput callback...
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                let assessmentData = Data(textOutputCallback.message.utf8)
                
                do {
                    if let assessmentDictionary = try JSONSerialization.jsonObject(with: assessmentData, options: []) as? [String: Any] {
                        // Assert that the custom payload and action has been taken into account...:
                        
                        let event = assessmentDictionary["event"] as! [String: Any]
                        let tokenProperties = assessmentDictionary["tokenProperties"] as! [String: Any]
                        let transactionData = event["transactionData"] as! [String: Any]
                        
                        let firewallPolicyEvaluation = event["firewallPolicyEvaluation"] as! Bool
                        let express = event["express"] as! Bool
                        let action = tokenProperties["action"] as! String // should be "custom_action" by default
                        let valid = tokenProperties["valid"] as! Bool // should be valid
                        
                        let transactionId = transactionData["transactionId"] as! String // should be "custom-payload-1234567890"
                        let paymentMthod = transactionData["paymentMethod"] as! String // should be "credit-card",
                        let cardBin = transactionData["cardBin"] as! String // should be "1111",
                        let cardLastFour = transactionData["cardLastFour"] as! String // should be "1234",
                        let currencyCode = transactionData["currencyCode"] as! String // should be "CAD",
                        
                        XCTAssertFalse(firewallPolicyEvaluation) // This is to prove that custom payload has been applied
                        XCTAssertFalse(express)
                        XCTAssertEqual(action, "custom_action")
                        XCTAssertTrue(valid)
                        
                        // These come from the custom payload:
                        XCTAssertEqual(transactionId, "custom-payload-1234567890")
                        XCTAssertEqual(paymentMthod, "credit-card")
                        XCTAssertEqual(cardBin, "1111")
                        XCTAssertEqual(cardLastFour, "1234")
                        XCTAssertEqual(currencyCode, "CAD")
                   }
                } catch let error as NSError {
                    XCTFail("Error parsing the assessment data \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the TextOutput callback and continue with the flow")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        /// At the end the user should be logged in
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_03_recaptcha_enterprise_fail_score() async throws {
        var currentNode: Node
        
        do {
            try currentNode = await startTest(nodeConfiguration: "score_failure")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a ReCaptchaEnterprise node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect ReCaptchaEnterpriseCallback callback here...
        for callback in currentNode.callbacks {
            if callback is ReCaptchaEnterpriseCallback, let reCaptchaEnterpriseCallback = callback as? ReCaptchaEnterpriseCallback {
                XCTAssertNotNil(reCaptchaEnterpriseCallback.recaptchaSiteKey)
                do {
                    try await reCaptchaEnterpriseCallback.execute()
                }
                catch let error as RecaptchaError {
                    XCTFail("reCaptchaEnterpriseCallback.execute() failed: \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit ReCaptchaEnterpriseCallback callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        // Confirm that reCAPTCHA Enterprise node execution fails (since the "Score threshold" is set to 1.0)
        // Note: Upon failure the test tree returns CaptchaEnterpriseNode.FAILURE in a TextOutput callback...
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertTrue(textOutputCallback.message.contains("VALIDATION_ERROR:CAPTCHA validation failed"))
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the TextOutput callback and continue with the flow")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        /// At the end the user should be logged in
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_04_recaptcha_enterprise_custom_client_error() async throws {
        var currentNode: Node
        
        do {
            try currentNode = await startTest(nodeConfiguration: "custom_client_error")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a ReCaptchaEnterprise node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect ReCaptchaEnterpriseCallback callback here...
        for callback in currentNode.callbacks {
            if callback is ReCaptchaEnterpriseCallback, let reCaptchaEnterpriseCallback = callback as? ReCaptchaEnterpriseCallback {
                do {
                    reCaptchaEnterpriseCallback.setClientError("CUSTOM_CLIENT_ERROR")
                    try await reCaptchaEnterpriseCallback.execute()
                }
                catch let error as RecaptchaError {
                    XCTFail("reCaptchaEnterpriseCallback.execute() failed: \(error)")
                }
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit ReCaptchaEnterpriseCallback callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        // Confirm that reCAPTCHA Enterprise node execution fails (since we have set client error)
        // Note: Upon failure the test tree returns CaptchaEnterpriseNode.FAILURE in a TextOutput callback...
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertTrue(textOutputCallback.message.contains("CLIENT_ERROR:CUSTOM_CLIENT_ERROR"))
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the TextOutput callback and continue with the flow")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        /// At the end the user should be logged in
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    /// Common steps for all test cases
    func startTest(nodeConfiguration: String) async throws -> Node  {
        var currentNode: Node?
        
        var ex = self.expectation(description: "Choose test case")
        FRSession.authenticate(authIndexValue: options.authServiceName) { (token: Token?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        // Provide input value for the username collector callback
        for callback in currentNode!.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_12_ReCaptchaEnterpriseCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username to the Username Collector Node")
        currentNode?.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        /// --------------------------------
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            throw AuthError.invalidCallbackResponse("Expected ChoiceCollector node, but got nothing...")
        }
        
        // Provide input value for the ChoiceCollector callback
        for callback in node.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                let choiceIndex = choiceCallback.choices.firstIndex(of: nodeConfiguration)
                choiceCallback.setValue(choiceIndex)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the ChoiceCollector Node")
        currentNode?.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        await fulfillment(of: [ex], timeout: 60.0)
        
        guard currentNode != nil else {
            XCTFail("Failed to get Node from the second request")
            throw AuthError.invalidCallbackResponse("Expected at least one more node, but got nothing...")
        }
        
        return currentNode!
    }
}
