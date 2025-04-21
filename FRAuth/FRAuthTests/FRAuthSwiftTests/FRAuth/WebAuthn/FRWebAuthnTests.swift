// 
//  FRWebAuthnTests.swift
//  FRAuthTests
//
//  Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

final class FRWebAuthnTests: WebAuthnSharedUtils {

    var relyingPartyId: String = "com.forgerock.ios.webauthn.registration.test"
    var excludeConsentResult: WebAuthnUserConsentResult?
    var createNewKeyConsentResult: WebAuthnUserConsentResult?
    static var registeredCredentialids: [[UInt8]] = []
    static var registeredKeyName: [String] = []
    var causeDelay: Int = 0
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        
        self.startSDK()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        FRWebAuthn.deleteCredentials(by: relyingPartyId)
        
        self.excludeConsentResult = nil
        self.createNewKeyConsentResult = nil
    }
    
    func test_01_loadAllCredentials() {
        //  Perform registration first
        self.performWebAuthnRegistration()
        
        //Load all discoverable credentials
        let registeredCredentials = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentials.count == 1)
    }
    
    func test_02_deleteByRpId() {
        //  Perform registration first
        self.performWebAuthnRegistration()
        //  Twice
        self.performWebAuthnRegistration()
        
        //Load all discoverable credentials
        let registeredCredentials = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentials.count == 2)
        
        //Delete all based on the RpId
        FRWebAuthn.deleteCredentials(by: relyingPartyId)
        
        //Load all discoverable credentials
        let registeredCredentialsAfterDeletion = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentialsAfterDeletion.count == 0)
        
    }
    
    func test_03_deleteWithCredential() {
        //  Perform registration first
        self.performWebAuthnRegistration()
        //  Twice
        self.performWebAuthnRegistration()
        
        //Load all discoverable credentials
        let registeredCredentials = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentials.count == 2)
        
        //Delete one by one based on the CredentialSource
        for credential in registeredCredentials {
            FRWebAuthn.deleteCredential(with: credential)
        }
        
        //Load all discoverable credentials
        let registeredCredentialsAfterDeletion = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentialsAfterDeletion.count == 0)
    }
    
    func test_04_deleteWithCredential_force_false() {
        //  Perform registration first
        self.performWebAuthnRegistration()
        
        //Load all discoverable credentials
        let registeredCredentials = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentials.count == 1)
        
        //Delete key using the CredentialSource
        let credential = registeredCredentials.first!
        XCTAssertThrowsError(try FRWebAuthn.deleteCredential(publicKeyCredentialSource: credential)) { error in
            guard case is AuthApiError = error else {
                return XCTFail()
            }
        }
        
        //Load all discoverable credentials
        let registeredCredentialsAfterDeletion = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentialsAfterDeletion.count == 1)
    }
    
    func test_05_deleteWithCredential_force_true() {
        //  Perform registration first
        self.performWebAuthnRegistration()
        
        //Load all discoverable credentials
        let registeredCredentials = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentials.count == 1)
        
        //Delete key using the CredentialSource
        let credential = registeredCredentials.first!
        try? FRWebAuthn.deleteCredential(publicKeyCredentialSource: credential, forceDelete: true)
        
        //Load all discoverable credentials
        let registeredCredentialsAfterDeletion = FRWebAuthn.loadAllCredentials(by: relyingPartyId)
        XCTAssertTrue(registeredCredentialsAfterDeletion.count == 0)
    }
    
    //  MARK: - Helper for registration
    
    fileprivate func performWebAuthnRegistration(requireResidentKey: Bool = false, userName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", displayName: String = "527490d2-0d91-483e-bf0b-853ff3bb2447", userId: String = "NTI3NDkwZDItMGQ5MS00ODNlLWJmMGItODUzZmYzYmIyNDQ3") {
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
            //  Require residentKey, to make the credential client discoverable.
            callback.requireResidentKey = true
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(usePasskeysIfAvailable: false, onSuccess: { (webAuthnOutcome) in
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
        FRWebAuthnTests.registeredCredentialids.append(credentialData.credentialId)
        FRWebAuthnTests.registeredKeyName.append(userCredentials.otherUI)
        //  Cause 1 second delay to avoid duplicate in KeyName
        sleep(1)
    }
    
}

extension FRWebAuthnTests: PlatformAuthenticatorRegistrationDelegate {
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
