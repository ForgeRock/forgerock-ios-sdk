// 
//  WebAuthnAuthenticationTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnAuthenticationTests: WebAuthnSharedUtils {

    //  MARK: - Properties
    var selectedKeyName: String?
    var relyingPartyId: String = "com.forgerock.ios.webauthn.authentication.test"
    var excludeConsentResult: WebAuthnUserConsentResult?
    var createNewKeyConsentResult: WebAuthnUserConsentResult?
    static var registeredCredentialids: [[UInt8]] = []
    static var registeredKeyName: [String] = []
    var causeDelay: Int = 0
    
    //  MARK: -
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        
        self.startSDK()
        //  Should not clean up the storage to re-use registered credentials from previous tests
        self.shouldCleanup = false
        self.causeDelay = 0
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        self.createNewKeyConsentResult = nil
        self.excludeConsentResult = nil
        self.selectedKeyName = nil
        
        if self.shouldCleanup {
            //  Clean up registered credentials if enforced
            let credentialStore = KeychainCredentialStore()
            let keychainStore = credentialStore.getKeychainStore(service: credentialStore.servicePrefix + self.relyingPartyId).keychainStore
            keychainStore.deleteAll()
        }
    }
    
    
    //  MARK: - Helper for registration
    
    func performWebAuthnRegistration(requireResidentKey: Bool = false, userName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", displayName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", userId: String = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3") {
        var result: String?
        
        //  Perform Registration first
        do {
            let callback = try self.createRegistrationCallback(userName: userName, displayName: displayName, userId: userId)
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set requireResidentKey
            callback.requireResidentKey = requireResidentKey
            //  Set delegate
            callback.delegate = self
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                result = webAuthnOutcome
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
        
        //  Make sure that successful WebAuthn outcome is captured
        guard let webAuthnResult = result else {
            XCTFail("Failed to capture successful WebAuthn result")
            return
        }
        
        //  Parse AttestationObject, AuthenticatorData, and AttestedCredentialData to extract credentialId from WebAuthnOutcome
        let credentialStore = KeychainCredentialStore()
        guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult), let credentialData = attestationObj.authData.attestedCredentialData, let userCredentials = credentialStore.lookupCredentialSource(rpId: self.relyingPartyId, credentialId: credentialData.credentialId) else {
            XCTFail("Failed to parse AuthenticatorData from WebAuthnOutcome result")
            return
        }
        //  Capture registered credential identifier
        WebAuthnAuthenticationTests.registeredCredentialids.append(credentialData.credentialId)
        WebAuthnAuthenticationTests.registeredKeyName.append(userCredentials.otherUI)
        //  Cause 1 second delay to avoid duplicate in KeyName
        sleep(1)
    }
    
    
    //  MARK: - WebAuthn Authentication tests
    
    func test_01_basic_authentication() {
        
        //  Perform registration first
        self.performWebAuthnRegistration()
        
        //  Retrieve credentialId
        guard let credentialId = WebAuthnAuthenticationTests.registeredCredentialids.first else {
            XCTFail("Failed to retrieve registered credentialId")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials
            callback.allowCredentials = [credentialId]
            
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_02_basic_authentication_with_multiple_credentials() {
        
        //  Perform registration first
        self.performWebAuthnRegistration()
        
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 2, WebAuthnAuthenticationTests.registeredKeyName.count == 2 else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials
            callback.allowCredentials = WebAuthnAuthenticationTests.registeredCredentialids
            
            //  Set keyName to be authenticated from the last registered credentials
            self.selectedKeyName = WebAuthnAuthenticationTests.registeredKeyName.last
            
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_03_allowed_credentials_does_not_exist_authentication() {
        
        var fakeAllowedCredentials: [[UInt8]] = []
        fakeAllowedCredentials.append([UInt8(217), UInt8(42), UInt8(155), UInt8(169), UInt8(187), UInt8(42), UInt8(67), UInt8(225), UInt8(160), UInt8(89), UInt8(206), UInt8(95), UInt8(179), UInt8(87), UInt8(236), UInt8(222)])
        fakeAllowedCredentials.append([UInt8(243), UInt8(254), UInt8(23), UInt8(83), UInt8(251), UInt8(255), UInt8(69), UInt8(111), UInt8(168), UInt8(58), UInt8(80), UInt8(187), UInt8(43), UInt8(154), UInt8(29), UInt8(235)])
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials
            callback.allowCredentials = fakeAllowedCredentials
            
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnAuthentication unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
                
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .notAllowed:
                        break
                    default:
                        XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                        break
                    }
                }
                else {
                    XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_04_usernameless_authentication_with_only_one_resident_key() {
        
        //  Perform registration first
        self.performWebAuthnRegistration(requireResidentKey: true)
        
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 3, WebAuthnAuthenticationTests.registeredKeyName.count == 3 else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials; empty the list for usernameless
            callback.allowCredentials = []
                        
            //  Since there is only one residentKey stored in storage,
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_05_usernameless_authentication_with_multiple_resident_keys() {
        
        //  Perform registration first
        self.performWebAuthnRegistration(requireResidentKey: true)
        
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 4, WebAuthnAuthenticationTests.registeredKeyName.count == 4 else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials; empty the list for usernameless
            callback.allowCredentials = []
            //  With two residentKey, userConsent to select keyName is required
            self.selectedKeyName = WebAuthnAuthenticationTests.registeredKeyName.last
                        
            //  Since there is only one residentKey stored in storage,
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_06_register_and_authenticate_with_different_user() {
        
        //  Perform registration first
        let userId = UUID().uuidString
        let userName = "forgerock_test_user"
        self.performWebAuthnRegistration(requireResidentKey: false, userName: userName, displayName: userName, userId: userId)
        
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 5, WebAuthnAuthenticationTests.registeredKeyName.count == 5, let credentialId = WebAuthnAuthenticationTests.registeredCredentialids.last else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials; set last registered user which is different from previous tests
            callback.allowCredentials = [credentialId]
                        
            //  Since there is only one residentKey stored in storage,
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_07_authentication_timeout() {
        
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 5, WebAuthnAuthenticationTests.registeredKeyName.count == 5 else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials;
            callback.allowCredentials = WebAuthnAuthenticationTests.registeredCredentialids
            //  Set timeout for 3 seconds
            callback.timeout = 3000
            //  Trigger delay for 10 seconds
            self.causeDelay = 10
                        
            //  Since there is only one residentKey stored in storage,
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnAuthentication unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
                
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .timeout:
                        break
                    default:
                        XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                        break
                    }
                }
                else {
                    XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                }
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_08_validate_signing_counter_for_credential_source() {
                
        //  Retrieve credentialId
        guard WebAuthnAuthenticationTests.registeredCredentialids.count == 5, WebAuthnAuthenticationTests.registeredKeyName.count == 5 else {
            XCTFail("Failed to retrieve registered credentialIds")
            return
        }
        
        do {
            let callback = try self.createAuthenticationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set allowedCredentials
            callback.allowCredentials = WebAuthnAuthenticationTests.registeredCredentialids
            
            //  Set keyName to be authenticated from the first registered credentials to increment counter
            self.selectedKeyName = WebAuthnAuthenticationTests.registeredKeyName.first
            
            //  Retrieve the currently used PublicKeyCredentialSource from the store
            let credentialStore = KeychainCredentialStore()
            guard let usedCredentialId = WebAuthnAuthenticationTests.registeredCredentialids.first else {
                XCTFail("Failed to retrieve used credentialId")
                return
            }
            //  Get credential to check the counter before the authentication
            let userCredentials = credentialStore.lookupCredentialSource(rpId: self.relyingPartyId, credentialId: usedCredentialId)
            //  Since the credential was used when it was originally registered, and this test, the counter should be two
            XCTAssertEqual(userCredentials?.signCount, 1)
            
            //  Perform Authentication
            let ex = self.expectation(description: "WebAuthn Authentication")
            callback.authenticate(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            //  Reload the used credential to validate if signing count has changed
            let credentialAfter = credentialStore.lookupCredentialSource(rpId: self.relyingPartyId, credentialId: usedCredentialId)
            XCTAssertEqual(credentialAfter?.signCount, 2)
        }
        catch {
            XCTFail("Failed to perform WebAuthn authentication: \(error.localizedDescription)")
        }
    }
    
    
    func test_99_clena_up() {
        //  Clean up all registered keys and credentials after entire authentication tests is done
        self.shouldCleanup = true
    }
}


extension WebAuthnAuthenticationTests: PlatformAuthenticatorAuthenticationDelegate {
    func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback) {
        if self.causeDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.causeDelay)) {
                selectionCallback(self.selectedKeyName)
            }
        }
        else {
            selectionCallback(self.selectedKeyName)
        }
    }
}


extension WebAuthnAuthenticationTests: PlatformAuthenticatorRegistrationDelegate {
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        if let result = self.excludeConsentResult {
            consentCallback(result)
        }
    }
    
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        if let result = self.createNewKeyConsentResult {
            consentCallback(result)
        }
    }
}
