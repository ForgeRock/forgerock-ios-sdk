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
@testable import PingProtect

class AA_09_PingOneProtectInitializeCallbackTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    let options = FROptions(url: "https://openam-sdks2.forgeblocks.com/am",
                            realm: "alpha",
                            enableCookie: true,
                            cookieName: "9dfa82bc124226d",
                            timeout: "180",
                            authServiceName: "TEST_PING_ONE_PROTECT_INITIALIZE",
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
    
    func test_01_protect_initialize_defaults() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "init-default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a PingOne Protect Initialize node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect PingOneProtectInitializeCallback callback with default values here...
        for callback in currentNode.callbacks {
            if callback is PingOneProtectInitializeCallback, let pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback {
                
                XCTAssertNotEqual(pingOneProtectInitializeCallback.envId, "")
                XCTAssertFalse(pingOneProtectInitializeCallback.consoleLogEnabled)
                XCTAssertTrue(pingOneProtectInitializeCallback.deviceAttributesToIgnore.count == 0)
                XCTAssertEqual(pingOneProtectInitializeCallback.customHost, "")
                XCTAssertFalse(pingOneProtectInitializeCallback.lazyMetadata)
                XCTAssertTrue(pingOneProtectInitializeCallback.behavioralDataCollection)
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
        
        // Provide input value for the username collector callback
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_09_PingOneProtectInitializeCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username collector node")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_protect_initialize_custom() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "init-custom")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a PingOne Protect Initialize node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect PingOneProtectInitializeCallback callback with custom values here...
        for callback in currentNode.callbacks {
            if callback is PingOneProtectInitializeCallback, let pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback {
                
                XCTAssertNotEqual(pingOneProtectInitializeCallback.envId, "")
                XCTAssertTrue(pingOneProtectInitializeCallback.consoleLogEnabled)
                XCTAssertTrue(pingOneProtectInitializeCallback.deviceAttributesToIgnore.count == 3)
                XCTAssertTrue(pingOneProtectInitializeCallback.deviceAttributesToIgnore.contains("Model"))
                XCTAssertTrue(pingOneProtectInitializeCallback.deviceAttributesToIgnore.contains("Manufacturer"))
                XCTAssertTrue(pingOneProtectInitializeCallback.deviceAttributesToIgnore.contains("Screen size"))
                XCTAssertEqual(pingOneProtectInitializeCallback.customHost, "custom.host.com")
                XCTAssertTrue(pingOneProtectInitializeCallback.lazyMetadata)
                XCTAssertFalse(pingOneProtectInitializeCallback.behavioralDataCollection)
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
        
        // Provide input value for the username collector callback
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_09_PingOneProtectInitializeCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username collector node")
        currentNode.next { (token: AccessToken?, node, error) in
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_03_protect_initialize_client_error() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "init-error")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a PingOne Protect Initialize node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect PingOneProtectInitializeCallback callback with default values here...
        for callback in currentNode.callbacks {
            if callback is PingOneProtectInitializeCallback, let pingOneProtectInitializeCallback = callback as? PingOneProtectInitializeCallback {
                
                pingOneProtectInitializeCallback.setClientError("Failed to initialize")
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
        
        // Provide input value for the TextOutputCallback callback
        for callback in currentNode.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Failure")
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
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node!
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Provide input value for the username collector callback
        for callback in currentNode.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_09_PingOneProtectInitializeCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Submit username collector node")
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
