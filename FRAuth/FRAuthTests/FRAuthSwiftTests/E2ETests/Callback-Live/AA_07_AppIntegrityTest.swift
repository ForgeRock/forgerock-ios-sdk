//
//  AA_07_APPINTEGRITYTEST.swift
//  FRAuthTests
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import XCTest
@testable import FRAuth

final class AA_07_AppIntegrityTest: CallbackBaseTest {
    
    static var USERNAME: String = "sdkuser"
    let options = FROptions(url: "https://localam.petrov.ca/openam",
                            realm: "root",
                            enableCookie: true,
                            cookieName: "iPlanetDirectoryPro",
                            authServiceName: "integrity",
                            oauthClientId: "iosclient",
                            oauthRedirectUri: "http://localhost:8081",
                            oauthScope: "openid profile email address"
    )
    
    var is14Available = false
    
    override func setUp() {
        super.setUp()
        if #available(iOS 14.0, *) {
            is14Available = true
        }
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
    
    func test_01_test_app_integrity_success() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        try XCTSkipIf(!Self.isRegisteredDeveloperDevice, "This test requires device to be refgistered with the ForgeRock developer account.")
        
        var currentNode: Node?
        
        do {
            try currentNode = startTest(testConfiguration: "default") /// Provide username and select "default" test configuration
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback (1st round...)
        var integrityCallback1: FRAppIntegrityCallback? = nil
        var attestToken1: String = String()
        var assertionToken1: String = String()
        var keyId1: String = String()
        var clientData1: String = String()
        
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback {
                integrityCallback1 = (callback as! FRAppIntegrityCallback)
                
                /// Make sure that the App Integrity node sends a challenge in the first callback
                XCTAssertNotEqual(integrityCallback1?.challenge, "")
                XCTAssertEqual(integrityCallback1?.attestToken, "") /// The attestation token from AM should be empty
                
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback1!.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                XCTAssertEqual(integrityResult, "Success")
                attestToken1 = (integrityCallback1?.inputValues["IDToken1attestToken"] as? String ?? "")
                keyId1 = (integrityCallback1?.inputValues["IDToken1keyId"] as? String ?? "")
                clientData1 = (integrityCallback1?.inputValues["IDToken1clientData"] as? String ?? "")
                assertionToken1 = (integrityCallback1?.inputValues["IDToken1token"] as? String ?? "")
                
                /// Make sure that the SDK sends attestation object, keyId and clientData to AM:
                XCTAssertNotEqual(attestToken1, "")
                XCTAssertNotEqual(keyId1, "")
                XCTAssertNotEqual(clientData1, "")
                
                /// Make sure that the assertion token input sent to AM is an empty string...
                XCTAssertEqual(assertionToken1, "")
                
                /// NB:
                /// keyId example: A1O8PV66FLxbCepSY62GVQUyqQ8tGfDJdDc4yPQcxXI=
                /// clientData eample: {"challenge":"S2cMzGG3t6mcqI90AOCC131KKN47dSrDvoYEoHjLwqc","bundleId":"com.forgerock.FRTestHost"}
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the AppIntegrity callback and continue...")
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
            XCTFail("Test Failed: Expected AppIntegrity callback, but got nothing...")
            return
        }
        
        /// We expect 2nd App Integrity callback...
        /// This is when the SDK generates an assertion token and AM will validate it...
        var integrityCallback2: FRAppIntegrityCallback
        var assertionToken2: String = String()
        
        for callback in node.callbacks {
            if callback is FRAppIntegrityCallback {
                integrityCallback2 = callback as! FRAppIntegrityCallback
            
                /// Expecting same challenge value as the first pass
                XCTAssertEqual(integrityCallback1!.challenge, integrityCallback2.challenge)
                
                /// attestToken should not be empty string on second pass... should be equal to "<keyId>::<attestToken>"
                XCTAssertEqual(integrityCallback2.attestToken, "\(keyId1)::\(attestToken1)")
                
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback2.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The request of the integrity token on client side should succeed. But will fail on server side, due to challenge mismatch...
                XCTAssertEqual(integrityResult, "Success")
                
                /// Test and ensure that the SDK generates an assertion token
                assertionToken2 = (integrityCallback2.inputValues["IDToken1token"] as? String ?? "")
                XCTAssertNotEqual(assertionToken2, "")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
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
        
        /// Make sure that the authentication journey finishes with "success" and provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Success" outcome...
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
        
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// At the end verify that the user has been successfully authenticated
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_02_test_app_integrity_fail_invalid_challenge() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        var currentNode: Node?
        
        do {
            try currentNode = startTest(testConfiguration: "default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // Prepare a AppIntegrity callback with "invalid" challenge (different from what AM sends)
        let jsonStr = """
            {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":"invalid"}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
            """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        let integrityCallbackNew = try FRAppIntegrityCallback(json: callbackResponse)
        currentNode?.callbacks = [integrityCallbackNew]
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
                
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Request Token")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : error?.localizedDescription ?? "error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The request of the integrity token on client side should succeed. But will fail on server side, due to challenge mismatch...
                XCTAssertEqual(integrityResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
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
        
        /// Provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has failed...
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
        
    func test_03_test_app_integrity_fail_empty_challenge() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        var currentNode: Node?
        
        do {
            try currentNode = startTest(testConfiguration: "default")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        /// Prepare an App Integrity callback with empty string challenge.
        /// This should cause error when invoking the requestIntegrityToken function
        let jsonStr = """
            {"type":"AppIntegrityCallback","output":[{"name":"challenge","value":""}, {"name":"attestToken","value":""}],"input":[{"name":"IDToken1clientError","value":""},{"name":"IDToken1attestToken","value":""},{"name":"IDToken1token","value":""},{"name":"IDToken1clientData","value":""},{"name":"IDToken1keyId","value":""}]}
            """
        
        let callbackResponse = self.parseStringToDictionary(jsonStr)
        
        let integrityCallbackNew = try FRAppIntegrityCallback(json: callbackResponse)
        currentNode?.callbacks = [integrityCallbackNew]
        
        // We expect App Integrity callback...
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
                
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    
                    /// Make sure that correct error has been thrown (invalidChallenge)
                    XCTAssertEqual((error as! FRDeviceCheckAPIFailure).rawValue, FRDeviceCheckAPIFailure.invalidChallenge.rawValue)
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The request of the integrity token on client side should fail and "Client Device Errors" is sent to AM
                XCTAssertEqual(integrityResult, "Error")
                
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
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
        
        /// Provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Client Device Errors" outcome...
                XCTAssertEqual(textOutputCallback.message, "Client Device Errors")
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
    
    func test_04_test_app_integrity_invalid_team_id() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        /// Test that when the Apple Team Identifier configured in the App Integrity node does NOT match the one of the calling app,
        /// the App Integrity node will fail
        var currentNode: Node?
        
        do {
            /// Provide username and select "invalid-team" test configuration
            /// in this case the Apple Team Identifier in the App Integrity node is set to "blah"
            try currentNode = startTest(testConfiguration: "invalid-team")
            
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback {
                let integrityCallback = (callback as! FRAppIntegrityCallback)
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The SDK successfully generates app attestation token, but the validation should fail in AM due to mismatching bundle id...
                XCTAssertEqual(integrityResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the AppIntegrity callback and continue...")
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
        
        /// Make sure that the authentication journey finishes with "failure" and provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Failure" outcome...
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
        
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// At the end verify that the user has been successfully authenticated
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_05_test_app_integrity_invalid_bundle_id() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        /// Test that when the Bundle Identifier configured in the App Integrity node does NOT match the one of the calling app,
        /// the App Integrity node will fail
        var currentNode: Node?
        
        do {
            /// Provide username and select "invalid-bundle-id" test configuration
            /// in this case the Apple Bundle Identifier in the App Integrity node is set to "blah"
            try currentNode = startTest(testConfiguration: "invalid-bundle-id")
            
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback {
                let integrityCallback = (callback as! FRAppIntegrityCallback)
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The SDK successfully generates app attestation token, but the validation should fail in AM due to mismatching team...
                XCTAssertEqual(integrityResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the AppIntegrity callback and continue...")
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
        
        /// Make sure that the authentication journey finishes with "failure" and provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Failure" outcome...
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
        
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// At the end verify that the user has been successfully authenticated
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_06_test_app_integrity_invalid_root_cert() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        /// Test that when the Attestation Root Certificate URL configured in the App Integrity node does is not the original CA cert,
        /// the App Integrity node will fail
        var currentNode: Node?
        
        do {
            /// Provide username and select "iinvalid-cert" test configuration
            /// in this case the Attestation Root Certificate URL in the App Integrity node is set to URL which returns
            /// certificate different from the Apple's Attestation Root Certificate
            try currentNode = startTest(testConfiguration: "invalid-cert")
            
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback {
                let integrityCallback = (callback as! FRAppIntegrityCallback)
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The SDK successfully generates app attestation token, but the validation should fail in AM due to invalid cert
                XCTAssertEqual(integrityResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the AppIntegrity callback and continue...")
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
        
        /// Make sure that the authentication journey finishes with "failure" and provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Failure" outcome...
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
        
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// At the end verify that the user has been successfully authenticated
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_07_test_app_integrity_fail_production() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        
        /// Test that when the App Integrity node is configured for production environment mode and the app is using sandbox (development) environment
        /// the App Integrity node will fail
        var currentNode: Node?
        
        do {
            /// Provide username and select "prod" test configuration
            /// in this case the Developer Mode toggle in the App Integrity node is OFF
            try currentNode = startTest(testConfiguration: "prod")
            
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback {
                let integrityCallback = (callback as! FRAppIntegrityCallback)
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity Success")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The SDK successfully generates app attestation token, but the validation should fail in AM because it is mismatching environment
                XCTAssertEqual(integrityResult, "Success")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit the AppIntegrity callback and continue...")
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
        
        /// Make sure that the authentication journey finishes with "failure" and provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Failure" outcome...
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
        
        currentNode?.next { (token: AccessToken?, node, error) in
            // Validate result
            XCTAssertNil(node)
            XCTAssertNil(error)
            XCTAssertNotNil(token)
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        /// At the end verify that the user has been successfully authenticated
        XCTAssertNotNil(FRUser.currentUser)
    }
    
    func test_08_test_app_integrity_unsupported() throws {
        try XCTSkipIf((is14Available && !self.isSimulator), "This test requires real device with iOS less than 14, or simulator.")
        
        /// Test that when the client app runs on simulator or on real device with smaller version of iOS 14, the requestIntegrityToken function throws "unsupported" error
        /// The App Integrity node will trigger the "unsupported" outcome
        var currentNode: Node?
        
        do {
            /// Provide username and select "default" test configuration
            try currentNode = startTest(testConfiguration: "default")
            
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occurred!")
            return
        }
        
        // We expect App Integrity callback
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
                
                var integrityResult = ""
                let ex = self.expectation(description: "App Integrity")
                
                integrityCallback.requestIntegrityToken { error in
                    integrityResult = (error == nil) ? "Success" : "Error"
                    
                    /// Make sure that correct error has been thrown (featureUnsupported)
                    XCTAssertEqual((error as! FRDeviceCheckAPIFailure).rawValue, FRDeviceCheckAPIFailure.featureUnsupported.rawValue)
                    ex.fulfill()
                }
                
                waitForExpectations(timeout: 60, handler: nil)
                
                /// The request of the integrity token on client side should fail and "Unsupported" client error is sent to AM
                XCTAssertEqual(integrityResult, "Error")
                
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
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
        
        /// Provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                // Make sure that the App Integriry node has triggered the "Unsupported" outcome...
                XCTAssertEqual(textOutputCallback.message, "Unsupported")
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
    
    func test_09_test_app_integrity_custom_outcome() throws {
        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "This test can only run on real devices above iOS14!")
        var currentNode: Node?
        
        do {
            /// Provide username and select "custom" test configuration
            /// in this case the App Integrity node is configured with custom client error outcome "Abort"
            try currentNode = startTest(testConfiguration: "custom")
        } catch AuthError.invalidCallbackResponse {
            XCTFail("Expected a App Integrity node, but got nothing!")
            return
        } catch {
            XCTFail("Unexpected error occured!")
            return
        }
        
        for callback in currentNode!.callbacks {
            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
                
                /// Set client error to "Abort" (this is
                integrityCallback.setClientError("Abort")
            }
            else {
                XCTFail("Received unexpected callback \(callback)")
            }
        }
        
        var ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
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
        
        /// Provide input value for the TextOutputCallback callback
        for callback in node.callbacks {
            if callback is TextOutputCallback, let textOutputCallback = callback as? TextOutputCallback {
                /// Make sure that the "Abort" client error oucome has been triggered
                XCTAssertEqual(textOutputCallback.message, "Abort")
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
        
        /// Dispite the error, the tree is configured to authenticated the user...
        XCTAssertNotNil(FRUser.currentUser)
    }
        
    /// Common steps for all test cases
    func startTest(testConfiguration: String) throws -> Node  {
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
                nameCallback.setValue(AA_07_AppIntegrityTest.USERNAME)
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
                let choiceIndex = choiceCallback.choices.firstIndex(of: testConfiguration)
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
