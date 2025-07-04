// 
//  FRAuthBaseTest.swift
//  FRAuthTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

@testable import FRCore
@testable import FRAuth

let FRTest = true


//  User object that contains randomly generated user information for each test case
struct RandomUser {
    let username: String
    let password: String
    let email: String
    let givenName: String
    let surname: String
    let kbaQuestionAnswers: [String: String]
}


class FRAuthBaseTest: FRBaseTestCase {
    
    //  MARK: - Properties
    
    static var randomeUser: RandomUser?

    
    //  MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        if self.shouldCleanup {
            self.cleanUp()
        }
    }
    
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        if self.shouldCleanup {
            self.cleanUp()
        }
    }
    
    
    //  MARK: - Helper methods
    
    @objc func cleanUp() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        FRUser._staticUser = nil
        FRDevice._staticDevice = nil
        Browser.currentBrowser = nil
    }
    
    @objc static func cleanUp() {
        if let frAuth = FRAuth.shared {
            frAuth.keychainManager.sharedStore.deleteAll()
            frAuth.keychainManager.privateStore.deleteAll()
            frAuth.keychainManager.cookieStore.deleteAll()
            frAuth.keychainManager.deviceIdentifierStore.deleteAll()
        }
        FRUser._staticUser = nil
        FRDevice._staticDevice = nil
        Browser.currentBrowser = nil
    }

    
    //  MARK: - SDK Helper methods
    
    func startSDK() {
        FRAuthBaseTest.startSDK(self.config)
    }
    
    
    func performLogin() {

        // Start SDK
        self.config.authServiceName = "Login"
        self.startSDK()

        // Set mock responses
        self.loadMockResponses(["AuthTree_LoginNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
        
        //  variable to capture the current Node object
        var currentNode: Node?
        
        //  To handle async operation for test; this allows async operation to be sync
        var ex = self.expectation(description: "First Node submit for Login")
        FRUser.login { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            XCTAssertNil(user)
            XCTAssertNotNil(node)
            currentNode = node
            //  Exit the async operation
            ex.fulfill()
        }
        //  Wait for async operation to be finished
        waitForExpectations(timeout: 60, handler: nil)
        
        //  To make sure that we captured Node object, and unwrap optional value of currentNode
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request from Registration tree")
            return
        }
        
        var username = config.username
        var password = config.password
        
        if let randomUsername = FRAuthBaseTest.randomeUser?.username, let randomPassword = FRAuthBaseTest.randomeUser?.password {
            username = randomUsername
            password = randomPassword
        }
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is ValidatedCreateUsernameCallback, let usernameCallback = callback as? ValidatedCreateUsernameCallback {
                usernameCallback.setValue(username)
            }
            else if callback is ValidatedCreatePasswordCallback, let passwordCallback = callback as? ValidatedCreatePasswordCallback {
                passwordCallback.setValue(password)
            }
            else if callback is NameCallback, let usernameCallback = callback as? NameCallback {
                usernameCallback.setValue(username)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                passwordCallback.setValue(password)
            }
            else {
                //  If Registration tree returns unexpected Callback, fail the test
                XCTFail("Received unexpected Callback from Login tree: \(callback.response)")
            }
        }
                
        ex = self.expectation(description: "Submit Node with inputs to complete Login tree")
        node.next { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        
        //  If Node is returned after user credentials with callback from Login tree
        //  it must be ProgressiveProfile tree, so handle it accordingly
        if let node = currentNode {
            // Provide input value for callbacks
            for callback in node.callbacks {
                if callback is BooleanAttributeInputCallback, let boolCallback = callback as? BooleanAttributeInputCallback {
                    //  If the Callback is BooleanAttributeInputCallback; provide appropriate value based on name of attribute
                    if boolCallback.name == "preferences/marketing" {
                        boolCallback.setValue(true)
                    }
                    else if boolCallback.name == "preferences/updates" {
                        boolCallback.setValue(true)
                    }
                    else {
                        //  If BooleanAttributeInputCallback attribute name is not known, fail the test
                        XCTFail("Received unexpected Callback from Registration tree: \(boolCallback.response)")
                    }
                }
                else {
                    //  If Registration tree returns unexpected Callback, fail the test
                    XCTFail("Received unexpected Callback from Registration tree: \(callback.response)")
                }
            }
            
            ex = self.expectation(description: "Submit Node with inputs to complete Login tree for ProgressiveProfile tree")
            node.next { (user: FRUser?, node, error) in
                //  Validate result
                XCTAssertNil(error)
                currentNode = node
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        
        //  Either with or without ProgressiveProfile, at this point, currentNode should be null
        //  and user must be authenticated
        XCTAssertNil(currentNode)
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
    }
    
    
    func performRegistration() {
        
        //  Should start SDK
        self.config.authServiceName = "Registration"
        self.startSDK()
        
        self.loadMockResponses(["AuthTree_RegistrationNode",
                                "AuthTree_SSOToken_Success",
                                "OAuth2_AuthorizeRedirect_Success",
                                "OAuth2_Token_Success"])
                
        //  variable to capture the current Node object
        var currentNode: Node?
        
        //  To handle async operation for test; this allows async operation to be sync
        var ex = self.expectation(description: "First Node submit for Registration")
        FRUser.register { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNil(error)
            XCTAssertNil(user)
            XCTAssertNotNil(node)
            currentNode = node
            //  Exit the async operation
            ex.fulfill()
        }
        //  Wait for async operation to be finished
        waitForExpectations(timeout: 60, handler: nil)
        
        //  To make sure that we captured Node object, and unwrap optional value of currentNode
        guard let node = currentNode else {
            XCTFail("Failed to get Node from the first request from Registration tree")
            return
        }
        
        //  Generate random username/password/email with ending special character
        let randomPassword = FRTestUtils.randomString(of: 10) + "!"
        let randomUsername = FRTestUtils.randomString(of: 10)
        let randomEmail = FRTestUtils.randomString(of: 5) + "@" + FRTestUtils.randomString(of: 8) + ".com"
        let randomGivenName = "iOS SDK Test" + FRTestUtils.randomString(of: 5)
        let randomSN = FRTestUtils.randomString(of: 5)
        var kbaQuestions: Set<String> = []
        var kbaQuestionAndAnswers: [String: String] = [:]
        
        
        // Provide input value for callbacks
        for callback in node.callbacks {
            if callback is ValidatedCreateUsernameCallback, let usernameCallback = callback as? ValidatedCreateUsernameCallback {
                //  If the Callback is ValidatedCreateUsernameCallback; provide randomly generated username
                usernameCallback.setValue(randomUsername)
            }
            else if callback is NameCallback, let usernameCallback = callback as? NameCallback {
                //  If the Callback is ValidatedCreateUsernameCallback; provide randomly generated username
                usernameCallback.setValue(randomUsername)
            }
            else if callback is StringAttributeInputCallback, let stringCallback = callback as? StringAttributeInputCallback {
                //  If the Callback is StringAttributeInputCallback; provide appropriate randomly generated value based on name of attribute
                if stringCallback.name == "givenName" {
                    stringCallback.setValue(randomGivenName)
                }
                else if stringCallback.name == "sn" {
                    stringCallback.setValue(randomSN)
                }
                else if stringCallback.name == "mail" {
                    stringCallback.setValue(randomEmail)
                }
                else {
                    //  If StringAttributeInputCallback attribute name is not known, fail the test
                    XCTFail("Received unexpected Callback from Registration tree: \(stringCallback.response)")
                }
                
            }
            else if callback is BooleanAttributeInputCallback, let boolCallback = callback as? BooleanAttributeInputCallback {
                //  If the Callback is BooleanAttributeInputCallback; provide appropriate value based on name of attribute
                if boolCallback.name == "preferences/marketing" {
                    boolCallback.setValue(true)
                }
                else if boolCallback.name == "preferences/updates" {
                    boolCallback.setValue(true)
                }
                else {
                    //  If BooleanAttributeInputCallback attribute name is not known, fail the test
                    XCTFail("Received unexpected Callback from Registration tree: \(boolCallback.response)")
                }
            }
            else if callback is ValidatedCreatePasswordCallback, let passwordCallback = callback as? ValidatedCreatePasswordCallback {
                //  If the Callback is ValidatedCreatePasswordCallback; provide randomly generated password
                passwordCallback.setValue(randomPassword)
            }
            else if callback is PasswordCallback, let passwordCallback = callback as? PasswordCallback {
                //  If the Callback is ValidatedCreatePasswordCallback; provide randomly generated password
                passwordCallback.setValue(randomPassword)
            }
            else if callback is KbaCreateCallback, let kbaCallback = callback as? KbaCreateCallback {
                
                //  If the KBA Questions were not tracked before, save it to Set
                if kbaQuestions.count == 0 {
                    for question in kbaCallback.predefinedQuestions {
                        kbaQuestions.insert(question)
                    }
                }
                
                for question in kbaCallback.predefinedQuestions {
                    
                    //  Only if the question has not been selected yet
                    if kbaQuestionAndAnswers.keys.contains(question) == false {
                        //  Set KBA question/answer map
                        let answer = FRTestUtils.randomString(of: 10)
                        kbaQuestionAndAnswers[question] = answer
                        
                        //  Set question/answer to Callback
                        kbaCallback.setQuestion(question)
                        kbaCallback.setAnswer(answer)
                        
                        //  Exit the loop
                        break
                    }
                }
                
            }
            else if callback is TermsAndConditionsCallback, let tcCallback = callback as? TermsAndConditionsCallback {
                //  Set true to agree with T&C
                tcCallback.setValue(true)
            }
            else {
                //  If Registration tree returns unexpected Callback, fail the test
                XCTFail("Received unexpected Callback from Registration tree: \(callback.response)")
            }
        }
        
        //  After we provided all inputs for user information, keep the randomly generated user info
        //  The reason that we are doing it after set all values is because of KBA
        let randomUser = RandomUser(username: randomUsername, password: randomPassword, email: randomEmail, givenName: randomGivenName, surname: randomSN, kbaQuestionAnswers: kbaQuestionAndAnswers)
        //  After creating RandomUser object, set it to static property of this test class for subsequent test cases later in this test file
        FRAuthBaseTest.randomeUser = randomUser
        
        ex = self.expectation(description: "Submit Node with inputs to complete Registration tree")
        node.next { (user: FRUser?, node, error) in
            //  Validate result
            XCTAssertNotNil(user)
            XCTAssertNil(error)
            XCTAssertNil(node)
            currentNode = node
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        //  User should be successfully registered and authenticated, and should also have OAuth2/Session Tokens
        XCTAssertNotNil(FRUser.currentUser)
        XCTAssertNotNil(FRUser.currentUser?.token)
        XCTAssertNotNil(FRSession.currentSession?.sessionToken)
    }
    
    
    //  MARK: - Static helper methods
    
    @objc static func startSDK(_ config: Config) {
        // Initialize SDK
        do {
            if let _ = config.configPlistFileName {
                try FRAuth.start()
                // Make sure FRAuth.shared is not nil
                guard let _ = FRAuth.shared else {
                    XCTFail("Failed to start SDK; FRAuth.shared returns nil")
                    return
                }
            }
            else if let serverConfig = config.serverConfig,
                let oAuth2Client = config.oAuth2Client,
                let sessionManager = config.sessionManager,
                let tokenManager = config.tokenManager,
                let keychainManager = config.keychainManager,
                let authServiceName = config.authServiceName,
                let registrationServiceName = config.registrationServiceName {
                
                FRAuth.shared = FRAuth(authServiceName: authServiceName, registerServiceName: registrationServiceName, serverConfig: serverConfig, oAuth2Client: oAuth2Client, tokenManager: tokenManager, keychainManager: keychainManager, sessionManager: sessionManager)
            }
            else {
                XCTFail("Failed to start SDK: invalid configuration file.")
            }
        }
        catch {
            XCTFail("Failed to start SDK: \(error)")
        }
    }
}
