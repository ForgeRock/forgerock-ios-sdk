// 
//  AA-05-DeviceBindingCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import FRDeviceBinding

class AA_05_DeviceBindingCallbackTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    let options = FROptions(url: "https://openam-sdks.forgeblocks.com/am",
                            realm: "alpha",
                            enableCookie: true,
                            cookieName: "afef1acb448a873",
                            timeout: "180",
                            authServiceName: "device-bind",
                            oauthThreshold: "60",
                            oauthClientId: "iosclient",
                            oauthRedirectUri: "http://localhost:8081",
                            oauthScope: "openid profile email address",
                            keychainAccessGroup: "com.bitbar.*"
                            )


    override func setUp() {
        super.setUp()
        do {
            try FRAuth.start(options: options)
        }
        catch {
            XCTFail("Fail to start the the SDK with custom config.")
        }
    }
    
    override func tearDown() {
        let userKeys = FRUserKeys().loadAll()
        
        for (_, userKey) in userKeys.enumerated()
        {
            do {
                try FRUserKeys().delete(userKey: userKey, forceDelete: true)
            }
            catch {
                FRLog.w("Failed to delete device binding keys.")
            }
        }
        FRSession.currentSession?.logout()
        super.tearDown()
    }
    
    func test_01_test_device_binding_defaults() {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Binding node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceBinding callback with default settings here. Assert its properties...
        for callback in currentNode.callbacks {
            if callback is DeviceBindingCallback, let deviceBindingCallback = callback as? DeviceBindingCallback {
                XCTAssertNotNil(deviceBindingCallback.userId)
//                XCTAssertEqual(deviceBindingCallback.userName, AA_05_DeviceBindingCallbackTest.USERNAME)
                XCTAssertNotNil(deviceBindingCallback.challenge)
                XCTAssertEqual(deviceBindingCallback.deviceBindingAuthenticationType, DeviceBindingAuthenticationType.biometricAllowFallback)
                XCTAssertEqual(deviceBindingCallback.title, "Authentication required")
                XCTAssertEqual(deviceBindingCallback.subtitle, "Cryptography device binding")
                XCTAssertEqual(deviceBindingCallback.promptDescription, "Please complete with biometric to proceed")
                XCTAssertEqual(deviceBindingCallback.timeout, 60)
                
                deviceBindingCallback.setClientError("Abort")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let ex = self.expectation(description: "Submit DeviceBinding callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_test_device_binding_custom() {
        var currentNode: Node?
        
        do {
            try currentNode = startTest(nodeConfiguration: "custom")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Binding node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceBinding callback with custom settings here. Assert its properties...
        for callback in currentNode!.callbacks {
            if callback is DeviceBindingCallback, let deviceBindingCallback = callback as? DeviceBindingCallback {
                
                XCTAssertNotNil(deviceBindingCallback.userId)
//                XCTAssertEqual(deviceBindingCallback.userName, AA_05_DeviceBindingCallbackTest.USERNAME)
                XCTAssertNotNil(deviceBindingCallback.challenge)
                XCTAssertEqual(deviceBindingCallback.deviceBindingAuthenticationType, DeviceBindingAuthenticationType.none)
                XCTAssertEqual(deviceBindingCallback.title, "Custom title")
                XCTAssertEqual(deviceBindingCallback.subtitle, "Custom subtitle")
                XCTAssertEqual(deviceBindingCallback.promptDescription, "Custom description")
                XCTAssertEqual(deviceBindingCallback.timeout, 5)
                
                // Set "Custom" client error - this should trigger the "Custom" outcome of the node
                deviceBindingCallback.setClientError("Custom")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit DeviceBinding callback and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Test Failed: Expected TextOutputCallback and ConfirmationCallback (returned by Message node), but got nothing...")
            return
        }
        
        // Provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Custom outcome triggered")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_03_test_device_binding_bind() throws {
        // Variable to capture the current Node object
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "custom")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Binding node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceBinding callback with default settings here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is DeviceBindingCallback, let deviceBindingCallback = callback as? DeviceBindingCallback {
                
                var bindingResult = ""
                let ex = self.expectation(description: "Device Binding")
                deviceBindingCallback.execute({ (result) in
                        switch result {
                        case .success:
                            bindingResult = "Success"
                        case .failure(let error):
                            bindingResult = error.errorMessage
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(bindingResult, "Success")

            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        let ex = self.expectation(description: "Submit DeviceBinding callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_04_test_device_binding_exceed() {
        var currentNode: Node?
        
        do {
            try currentNode = startTest(nodeConfiguration: "exceed-limit")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Binding node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceBinding callback to trigger the "Exceed Device Limit" outcome
        for callback in currentNode!.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Device Limit Exceeded")
            }
            else if callback is ConfirmationCallback, let confirmationCallback = callback as? ConfirmationCallback {
                confirmationCallback.value = 0
            }
            else {
                XCTFail("Device bind node did NOT trigger the expected 'Exceeded Device Limit' outcome")
            }
        }
        
        let ex = self.expectation(description: "Submit value for the ConfirmationCallback and continue...")
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate resultF
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_05_test_device_binding_wrong_app_id() throws {
        var currentNode: Node
        
        do {
            try currentNode = startTest(nodeConfiguration: "wrong-app-id")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Binding node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceBinding callback with wrong app id settings here. Assert its properties. . .
        for callback in currentNode.callbacks {
            if callback is DeviceBindingCallback, let deviceBindingCallback = callback as? DeviceBindingCallback {
                
                var bindingResult = ""
                let ex = self.expectation(description: "Device Binding")
                deviceBindingCallback.execute({ (result) in
                        switch result {
                        case .success:
                            bindingResult = "Success"
                        case .failure(let error):
                            bindingResult = error.errorMessage
                        };
                        ex.fulfill()
                    })
                waitForExpectations(timeout: 60, handler: nil)
                
                
                XCTAssertEqual(bindingResult, "Success")

            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        
        let ex = self.expectation(description: "Submit DeviceBinding callback and continue...")
        currentNode.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNotNil(error)
            XCTAssertNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNil(FRUser.currentUser)
    }
    
    /// Common steps for all test cases
    func startTest(nodeConfiguration: String) throws -> Node  {
        var currentNode: Node?
        
        var ex = self.expectation(description: "Provide username")
        
        FRSession.authenticate(authIndexValue: options.authServiceName) { (token: Token?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request")
            throw AuthError.invalidCallbackResponse("Expected username collector node, but got nothing...")
        }
        
        // Provide input value for the username collector callback
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_05_DeviceBindingCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Second Node submit")
        currentNode?.next { (token: AccessToken?, node, error) in
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
            // Validate result
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
