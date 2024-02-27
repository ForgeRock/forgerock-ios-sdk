//
//  AA_10_PingOneProtectEvaluateCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import PingProtect

class AA_10_PingOneProtectEvaluateCallbackTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    let options = FROptions(url: "https://openam-protect2.forgeblocks.com/am",
                            realm: "alpha",
                            enableCookie: true,
                            cookieName: "c1c805de4c9b333",
                            timeout: "180",
                            authServiceName: "TEST_PING_ONE_PROTECT_EVALUATE",
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
    
    func test_01_protect_evaluate_no_init() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "evaluate-no-init")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected username  collector node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // Provide username
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_10_PingOneProtectEvaluateCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        var ex = self.expectation(description: "Submit username")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Handle PingOneProtectEvaluationCallback
        for callback in currentNode.callbacks {
            if callback is PingOneProtectEvaluationCallback, let pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback {
                
                var evaulationResult = ""
                
                // Try to getData without initializing the Signals SDK. This should result in error...
                let ex = self.expectation(description: "PingOne Protect Evaluate")
                pingOneProtectEvaluationCallback.getData(completion: { (result) in
                        switch result {
                        case .success:
                            evaulationResult = "Success"
                        case .failure(let error):
                            evaulationResult = error.localizedDescription
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(evaulationResult, "SDK is not initialized")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the PingOneProtectEvaluation callback ")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Confirm that AM returns Client Error and provide input value for the TextOutputCallback callback
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Client Error")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_protect_evaluate_success() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "evaluate-default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a PingOne Protect Initialize node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // Handle the PingOneProtectInitializeCallback callback
        for callback in currentNode.callbacks {
            if callback is PingOneProtectInitializeCallback, let pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback {
                
                var initResult = ""
                let ex = self.expectation(description: "PingOne Protect Init")
                pingOneProtectInitializeCallback.start(completion: { (result) in
                        switch result {
                        case .success:
                            initResult = "Success"
                        case .failure(let error):
                            initResult = error.localizedDescription
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(initResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit PingOneProtectInitialize callback and continue...")
            currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
            
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Provide username
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_10_PingOneProtectEvaluateCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username collector node")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Handle PingOneProtectEvaluationCallback
        for callback in currentNode.callbacks {
            if callback is PingOneProtectEvaluationCallback, let pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback {
                
                XCTAssertTrue(pingOneProtectEvaluationCallback.pauseBehavioralData)
                
                var evaulationResult = ""
                let ex = self.expectation(description: "PingOne Protect Evaluate")
                pingOneProtectEvaluationCallback.getData(completion: { (result) in
                        switch result {
                        case .success:
                            evaulationResult = "Success"
                        case .failure(let error):
                            evaulationResult = error.localizedDescription
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(evaulationResult, "Success")
                
                /// Ensure that Signals data is not empty after collection
                XCTAssertTrue(pingOneProtectEvaluationCallback.inputValues["IDToken1signals"] as! String != "")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the PingOneProtectEvaluation callback ")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Confirm that AM returns "success"
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_03_protect_evaluate_pause_behavioral_data_off() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "evaluate-pause-off")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a PingOne Protect Initialize node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // Handle the PingOneProtectInitializeCallback callback
        for callback in currentNode.callbacks {
            if callback is PingOneProtectInitializeCallback, let pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback {
                
                var initResult = ""
                let ex = self.expectation(description: "PingOne Protect Init")
                pingOneProtectInitializeCallback.start(completion: { (result) in
                        switch result {
                        case .success:
                            initResult = "Success"
                        case .failure(let error):
                            initResult = error.localizedDescription
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(initResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit PingOneProtectInitialize callback and continue...")
            currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
            
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Provide username
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_10_PingOneProtectEvaluateCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username collector node")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Handle PingOneProtectEvaluationCallback
        for callback in currentNode.callbacks {
            if callback is PingOneProtectEvaluationCallback, let pingOneProtectEvaluationCallback = callback as? PingOneProtectEvaluationCallback {
                
                XCTAssertFalse(pingOneProtectEvaluationCallback.pauseBehavioralData)
                
                var evaulationResult = ""
                let ex = self.expectation(description: "PingOne Protect Evaluate")
                pingOneProtectEvaluationCallback.getData(completion: { (result) in
                        switch result {
                        case .success:
                            evaulationResult = "Success"
                        case .failure(let error):
                            evaulationResult = error.localizedDescription
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(evaulationResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit the PingOneProtectEvaluation callback ")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Confirm that AM returns "success"
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    /// Common steps for all test cases
    func startTest(nodeConfiguration: String) throws -> Node  {
        var currentNode: Node?
        
        var ex = self.expectation(description: "Select test configuration")
        
        FRSession.authenticate(authIndexValue: options.authServiceName) { (token: Token?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
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
        waitForExpectations(timeout: 60, handler: nil)
        
        guard currentNode != nil else {
            XCTFail("Failed to get Node from the second request")
            throw AuthError.invalidCallbackResponse("Expected at least one more node, but got nothing...")
        }
        return currentNode!
    }
}
