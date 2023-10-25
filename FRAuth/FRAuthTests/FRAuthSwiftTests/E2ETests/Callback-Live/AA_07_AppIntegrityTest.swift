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
    let options = FROptions(url: "http://192.168.1.93:8080/openam",
                            realm: "root",
                            enableCookie: true,
                            cookieName: "afef1acb448a873",
                            authServiceName: "integrity",
                            oauthClientId: "iosclient",
                            oauthRedirectUri: "http://localhost:8081",
                            oauthScope: "openid profile email address"
    )
    
    var is14Available = false
    
    
//    override func setUp() {
//        super.setUp()
//        if #available(iOS 14.0, *) {
//            is14Available = true
//        }
//        do {
//            try FRAuth.start(options: options)
//        }
//        catch {
//            XCTFail("Fail to start the the SDK with custom config.")
//        }
//    }
//    
//    override func tearDown() {
//        FRSession.currentSession?.logout()
//        super.tearDown()
//    }
//    
//    func test_01_test_app_integrity_failures() throws {
//        
//        try XCTSkipIf(!self.isSimulator, "only run in the simulator , not in device")
//        
//        // Variable to capture the current Node object
//        var currentNode: Node
//        
//        do {
//            try currentNode = startTest()
//        } catch AuthError.invalidCallbackResponse {
//            XCTFail("Expected a App Integrity node, but got nothing!")
//            return
//        } catch {
//            XCTFail("Unexpected error occured!")
//            return
//        }
//        
//        // We expect App Integrity callback with default settings here. Assert its properties. . .
//        for callback in currentNode.callbacks {
//            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
//                
//                var bindingResult = ""
//                let ex = self.expectation(description: "App Integrity")
//                
//                integrityCallback.requestIntegrityToken { error in
//                    
//                    bindingResult = (error == nil) ? "Success" : "failure"
//                    ex.fulfill()
//                    
//                }
//                
//                waitForExpectations(timeout: 60, handler: nil)
//                
//                XCTAssertEqual(bindingResult, "failure")
//                
//            }
//            else {
//                XCTFail("Received unexpected callback \(callback)")
//            }
//        }
//        
//        let ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
//        currentNode.next { (token: AccessToken?, node, error) in
//            // Validate result
//            XCTAssertNil(node)
//            XCTAssertNotNil(error)
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 60, handler: nil)
//        
//    }
//    
    // This test is skipped , unskip when its ready in AM
//    func test_01_test_app_integrity() throws {
//        
//        try XCTSkipIf(self.isSimulator || (!is14Available && !self.isSimulator), "only run the device above iOS14, not in sumulator")
//        
//        // Variable to capture the current Node object
//        var currentNode: Node
//        
//        do {
//            try currentNode = startTest()
//        } catch AuthError.invalidCallbackResponse {
//            XCTFail("Expected a App Integrity node, but got nothing!")
//            return
//        } catch {
//            XCTFail("Unexpected error occured!")
//            return
//        }
//        
//        // We expect App Integrity callback with default settings here. Assert its properties. . .
//        for callback in currentNode.callbacks {
//            if callback is FRAppIntegrityCallback, let integrityCallback = callback as? FRAppIntegrityCallback {
//                
//                var bindingResult = ""
//                let ex = self.expectation(description: "App Integrity")
//                
//                integrityCallback.requestIntegrityToken { error in
//                    
//                    bindingResult = (error == nil) ? "Success" : error?.localizedDescription ?? "error"
//                    ex.fulfill()
//                    
//                }
//                
//                waitForExpectations(timeout: 60, handler: nil)
//                
//                XCTAssertEqual(bindingResult, "Success")
//                
//            }
//            else {
//                XCTFail("Received unexpected callback \(callback)")
//            }
//        }
//        
//        let ex = self.expectation(description: "Submit AppIntegrity callback and continue...")
//        currentNode.next { (token: AccessToken?, node, error) in
//            // Validate result
//            XCTAssertNil(node)
//            XCTAssertNil(error)
//            XCTAssertNotNil(token)
//            ex.fulfill()
//        }
//        waitForExpectations(timeout: 60, handler: nil)
//        
//        XCTAssertNotNil(FRUser.currentUser)
//    }
//    
    /// Common steps for all test cases
    func startTest() throws -> Node  {
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
        
        return currentNode!
    }
}
