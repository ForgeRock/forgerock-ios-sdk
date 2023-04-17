//
//  AA-06-DeviceSigningVerifierCallbackTest.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth
@testable import FRDeviceBinding

class AA_06_DeviceSigningVerifierCallbackTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    static var APPLICATION_PIN: String = "1111"
    
    let options = FROptions(url: "https://openam-sdks-dbind.forgeblocks.com/am",
                            realm: "alpha",
                            enableCookie: true,
                            cookieName: "afef1acb448a873",
                            timeout: "180",
                            authServiceName: "device-verifier",
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
            CallbackFactory.shared.registerCallback(callbackType: "DeviceBindingCallback", callbackClass: DeviceBindingCallback.self)
            CallbackFactory.shared.registerCallback(callbackType: "DeviceSigningVerifierCallback", callbackClass: DeviceSigningVerifierCallback.self)
        }
        catch {
            XCTFail("Fail to start the the SDK with custom config.")
        }
    }
    
    override func tearDown() {
        FRUser.currentUser?.logout()
        super.tearDown()
    }
    
    func test_01_test_device_signing_verifier_defaults() throws {
        var currentNode: Node?
        
        do {
            try currentNode = startTest(testConfiguration: "default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Signing Verifier node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        // We expect DeviceSigningVerifier callback with default settings here. Assert its properties and abort...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                XCTAssertNotNil(deviceSigningVerifierCallback.userId)
                XCTAssertNotNil(deviceSigningVerifierCallback.challenge)
                XCTAssertEqual(deviceSigningVerifierCallback.title, "Authentication required")
                XCTAssertEqual(deviceSigningVerifierCallback.subtitle, "Cryptography device binding")
                XCTAssertEqual(deviceSigningVerifierCallback.promptDescription, "Please complete with biometric to proceed")
                XCTAssertEqual(deviceSigningVerifierCallback.timeout, 60)
                
                deviceSigningVerifierCallback.setClientError("Abort")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ensusre that a TextCallback was received with message "Abort"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Abort")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Finish the journey") // Should finish with success and user should be logged in
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_test_device_signing_verifier_custom() throws {
        var currentNode: Node?
        
        do {
            try currentNode = startTest(testConfiguration: "custom")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a Device Signing Verifier node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        /// We expect DeviceSigningVerifier callback with custom settings here. Assert its properties and set "custom" client error (should trigger the "custom" outcome of the node)
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                XCTAssertNotNil(deviceSigningVerifierCallback.userId)
                XCTAssertEqual(deviceSigningVerifierCallback.challenge, "my-hardcoded-challenge")
                XCTAssertEqual(deviceSigningVerifierCallback.title, "Custom Title")
                XCTAssertEqual(deviceSigningVerifierCallback.subtitle, "Custom Subtitle")
                XCTAssertEqual(deviceSigningVerifierCallback.promptDescription, "Custom Description")
                XCTAssertEqual(deviceSigningVerifierCallback.timeout, 0)
                
                deviceSigningVerifierCallback.setClientError("Custom")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// Ensusre that a TextCallback is received with message "Custom"
        guard let node = currentNode else {
            XCTFail("Failed to get next node...")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Custom")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Finish the journey") // Should finish with success and user should be logged in
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_03_test_device_signing_verifier_with_username_collector() throws {
        // Bind the device with authentication type "None"
        try bindDevice(nodeConfiguration: "bind")
        
        // Advance to the Device Signing Verifier node...
        var currentNode: Node? = try startTest(testConfiguration: "default")
        
        // We expect DeviceSigningVerifier callback at this point...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                var singningResult = ""
                
                let ex = self.expectation(description: "Signing the challange (verify the device)")
                deviceSigningVerifierCallback.sign(completion: { result in
                    switch result {
                    case .success:
                        singningResult = "Success"
                    case .failure(let error):
                        singningResult = error.errorMessage
                    };
                    ex.fulfill()
                })
                waitForExpectations(timeout: 60, handler: nil)
                XCTAssertEqual(singningResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        // Verify that the server verified the JWT successfully (Device Signing Verifier should trigger the "Success" outcome...)
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ensusre that a TextOutputCallback is received with message "Success"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Finish the journey")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_04_test_device_signing_verifier_usernameless() throws {
        // Bind the device with authentication type "None"
        try bindDevice(nodeConfiguration: "bind")
        
        // Advance to the Device Signing Verifier node...
        var currentNode: Node? = try startTest(testConfiguration: "usernameless")
        
        // We expect DeviceSigningVerifier callback at this point...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                var singningResult = ""
                
                let ex = self.expectation(description: "Signing the challange (verify the device)")
                deviceSigningVerifierCallback.sign(completion: { result in
                    switch result {
                    case .success:
                        singningResult = "Success"
                    case .failure(let error):
                        singningResult = error.errorMessage
                    };
                    ex.fulfill()
                })
                waitForExpectations(timeout: 60, handler: nil)
                XCTAssertEqual(singningResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        // Verify that the server verified the JWT successfully (Device Signing Verifier should trigger the "Success" outcome...)
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ensusre that a TextOutputCallback is received with message "Success"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Finish the journey")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_05_test_device_signing_verifier_timout() throws {
        // Bind the device with authentication type "None"
        try bindDevice(nodeConfiguration: "bind")
        
        // Advance to the Device Signing Verifier node...
        // Note that the "custom" Device Signing Verifier node is configured with timout=0
        var currentNode: Node? = try startTest(testConfiguration: "custom")
        
        // We expect DeviceSigningVerifier callback at this point...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                var singningResult = ""
                
                let ex = self.expectation(description: "Signing the challange (verify the device)")
                deviceSigningVerifierCallback.sign(completion: { result in
                    switch result {
                    case .success:
                        singningResult = "Success"
                    case .failure(let error):
                        singningResult = error.errorMessage
                    };
                    ex.fulfill()
                })
                waitForExpectations(timeout: 60, handler: nil)
                XCTAssertEqual(singningResult, "Authentication Timeout")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        // Verify that the server verified the JWT successfully (Device Signing Verifier should trigger the "Timout" outcome...)
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Ensusre that a TextOutputCallback is received with message "Timeout"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }
        
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Timeout")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Finish the journey")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_06_test_device_signing_verifier_pin() throws {
        
        // This test fails on simulator
        try XCTSkipIf(isSimulator, "Cannot run this test on simulator")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        
        // Bind the device with authentication type "APPLICATION_PIN"
        try bindDevice(nodeConfiguration: "bind-pin")
        
        // Advance to the Device Signing Verifier node...
        var currentNode: Node? = try startTest(testConfiguration: "default")

        // We expect DeviceSigningVerifier callback at this point...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                
                var singningResult = ""
                
                let customDeviceBindingIdentifier: (DeviceBindingAuthenticationType) -> DeviceAuthenticator =  { type in
                    return ApplicationPinDeviceAuthenticator(pinCollector: CustomPinCollector(pin: AA_06_DeviceSigningVerifierCallbackTest.APPLICATION_PIN))
                }
                
                let ex = self.expectation(description: "Signing the challange (verify the device)")
                deviceSigningVerifierCallback.sign(
                    deviceAuthenticator: customDeviceBindingIdentifier,
                    completion: { result in
                        switch result {
                        case .success:
                            singningResult = "Success"
                        case .failure(let error):
                            singningResult = error.errorMessage
                        };
                        ex.fulfill()
                    })

                waitForExpectations(timeout: 60, handler: nil)
                XCTAssertEqual(singningResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        // Verify that the server verified the JWT successfully (Device Signing Verifier should trigger the "Success" outcome...)
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        // Ensusre that a TextOutputCallback is received with message "Success"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }

        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Success")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Finish the journey")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_07_test_device_signing_verifier_wrong_pin() throws {
        
        // This test fails on simulator
        try XCTSkipIf(isSimulator, "Cannot run this test on simulator")
        try XCTSkipIf(!Self.biometricTestsSupported, "This test requires PIN setup on the device")
        
        // Bind the device with authentication type "APPLICATION_PIN"
        try bindDevice(nodeConfiguration: "bind-pin")
        
        // Advance to the Device Signing Verifier node...
        var currentNode: Node? = try startTest(testConfiguration: "default")

        // We expect DeviceSigningVerifier callback at this point...
        for callback in currentNode!.callbacks {
            if callback is DeviceSigningVerifierCallback, let deviceSigningVerifierCallback = callback as? DeviceSigningVerifierCallback {
                
                var singningResult = ""
                
                // Setup custom application pin authenticator, and provide wrong pin
                let customDeviceBindingIdentifier: (DeviceBindingAuthenticationType) -> DeviceAuthenticator =  { type in
                    return ApplicationPinDeviceAuthenticator(pinCollector: CustomPinCollector(pin: "WRONG-PIN"))
                }
                
                let ex = self.expectation(description: "Signing the challange - should fail with 'Invalid Credentials' error")
                deviceSigningVerifierCallback.sign(
                    deviceAuthenticator: customDeviceBindingIdentifier,
                    completion: { result in
                        switch result {
                        case .success:
                            singningResult = "Success"
                        case .failure(let error):
                            singningResult = error.errorMessage
                        };
                        ex.fulfill()
                    })

                waitForExpectations(timeout: 60, handler: nil)
                XCTAssertEqual(singningResult, "Invalid Credentials")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        // Verify that the "Unsupported" outcome was triggered in AM...
        var ex = self.expectation(description: "Submit DeviceSigningVerifier callback and continue...")
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(node)
            XCTAssertNil(error)
            XCTAssertNil(token)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)

        // Ensusre that a TextOutputCallback is received with message "Unsupported"
        guard let node = currentNode else {
            XCTFail("Failed to get next node")
            throw AuthError.invalidCallbackResponse("Expected TextOutputCallback, but got nothing...")
        }

        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                XCTAssertEqual(textOutputCallback.message, "Abort")
                break
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }

        ex = self.expectation(description: "Finish the journey")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNotNil(error)
            XCTAssertNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // User should not have been authenticated...
        XCTAssertNil(FRUser.currentUser)
    }
    
    /// Bind a device
    /// Possible values for nodeConfiguration are "bind" or "bind-pin"
    func bindDevice(nodeConfiguration: String) throws {
        var currentNode: Node?
        
        // Process ChoiceCollector node... (first node)
        var ex = self.expectation(description: "Select 'collectusername' choice")
        
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
            XCTFail("Failed to get node from the first request")
            throw AuthError.invalidCallbackResponse("Expected Choice Collector node, but got nothing...")
        }
        
        // Select 'collectusername' value for the Choice Collector callback
        for callback in node.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                let choiceIndex = choiceCallback.choices.firstIndex(of: "collectusername")
                choiceCallback.setValue(choiceIndex)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the ChoiceCollector Node")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let node = currentNode else {
            XCTFail("Failed to get Username Collector node")
            throw AuthError.invalidCallbackResponse("Expected Username Collector node, but got nothing...")
        }
        
        // Process Username Collector node... (second node)
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_06_DeviceSigningVerifierCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the NameCollector node")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // Process Choice Collector node... (third node)
        guard let node = currentNode else {
            XCTFail("Failed to get Choice Collector node")
            throw AuthError.invalidCallbackResponse("Expected ChoiceCollector node, but got nothing...")
        }
        
        // Provide input value for the ChoiceCollector callback (valid options are "bind" or "bind-pin")
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
        
        // Process the DeviceBinding node... (fourth node)
        guard currentNode != nil else {
            XCTFail("Failed to get DeviceBinding node after selecting \(nodeConfiguration)...")
            throw AuthError.invalidCallbackResponse("Expected DeviceBinding node, but got nothing...")
        }

        // We expect DeviceBinding callback here.
        // Depending on the nodeConfiguration ("bind" or "bind-pin"), the authentication type should be either "NONE" or "APPLICATION_PIN"
        for callback in currentNode!.callbacks {
            if callback is DeviceBindingCallback, let deviceBindingCallback = callback as? DeviceBindingCallback {
                // Bind the device...
                var bindingResult = ""
                var applicationPinDeviceAuthenticator: ApplicationPinDeviceAuthenticator? = nil
                if nodeConfiguration == "bind-pin" {
                    applicationPinDeviceAuthenticator = ApplicationPinDeviceAuthenticator.init(pinCollector: CustomPinCollector(pin: AA_06_DeviceSigningVerifierCallbackTest.APPLICATION_PIN))
                }
                
                let ex = self.expectation(description: "Device Binding")
                deviceBindingCallback.execute(authInterface: applicationPinDeviceAuthenticator, { (result) in
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

        ex = self.expectation(description: "Submit DeviceBinding callback...") // The journey should finish with "Success" and user logged in...
        currentNode!.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNotNil(token)
            XCTAssertNil(node)
            XCTAssertNil(error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        XCTAssertNotNil(FRUser.currentUser)
        
        // Logout the user
        FRUser.currentUser?.logout()
    }
    
    /// Helper function for processing common steps in test cases
    /// Valid values for "testConfiguration" are "usernameless", "default" or "custom"...
    func startTest(testConfiguration: String) throws -> Node  {
        var currentNode: Node?
        
        /// Process ChoiceCollector node... (first node)
        var ex = self.expectation(description: "Select 'collectusername' choice")
        
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
            XCTFail("Failed to get node from the first request")
            throw AuthError.invalidCallbackResponse("Expected Choice Collector node, but got nothing...")
        }

        // Select the choice option provided in the "testConfiguration" parameter
        for callback in node.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                var choiceIndex = 0
                if testConfiguration == "usernameless" {
                    choiceIndex = choiceCallback.choices.firstIndex(of: "usernameless")!
                }
                else {
                    choiceIndex = choiceCallback.choices.firstIndex(of: "collectusername")!
                }
                choiceCallback.setValue(choiceIndex)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the ChoiceCollector Node")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        // For usernamless flow we don't need to collect username, so we return the current node.
        if testConfiguration == "usernameless" {
            return currentNode!
        }
        
        // For other cases continue processing...
        guard let node = currentNode else {
            XCTFail("Failed to get Node")
            throw AuthError.invalidCallbackResponse("Expected username collector node, but got nothing...")
        }
        
        // Process UserName collector node... (second node)
        for callback in node.callbacks {
            if callback is NameCallback, let nameCallback = callback as? NameCallback {
                nameCallback.setValue(AA_06_DeviceSigningVerifierCallbackTest.USERNAME)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the NameCollector node")
        node.next { (token: AccessToken?, node, error) in
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
            throw AuthError.invalidCallbackResponse("Expected Choice Collector node, but got nothing...")
        }
        
        // Select the selected "testConfiguration" option in the ChoiceCollector.
        // The journey should the advance to one of the "DeviceSigningVerifier" nodes (either "default" or "custom")
        for callback in node.callbacks {
            if callback is ChoiceCallback, let choiceCallback = callback as? ChoiceCallback {
                let choiceIndex = choiceCallback.choices.firstIndex(of: testConfiguration)
                choiceCallback.setValue(choiceIndex)
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit value to the ChoiceCollector Node")
        node.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(token)
            XCTAssertNil(error)
            XCTAssertNotNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        return currentNode! // Should be the DeviceSigningVerifier node
    }
    
    class CustomPinCollector: PinCollector {
        private var pin : String = ""
        
        required public init(pin : String) {
            self.pin = pin
        }
        
        func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void) {
            completion(self.pin)
        }
    }
    
}
