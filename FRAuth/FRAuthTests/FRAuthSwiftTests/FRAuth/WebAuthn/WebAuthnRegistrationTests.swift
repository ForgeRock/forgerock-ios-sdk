// 
//  WebAuthnRegistrationTests.swift
//  FRAuthTests
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRAuth

class WebAuthnRegistrationTests: WebAuthnSharedUtils {

    var relyingPartyId: String = "com.forgerock.ios.webauthn.registration.test"
    var excludeConsentResult: WebAuthnUserConsentResult?
    var createNewKeyConsentResult: WebAuthnUserConsentResult?
    
    override func setUp() {
        self.configFileName = "Config"
        super.setUp()
        
        self.startSDK()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        let credentialStore = KeychainCredentialStore()
        let keychainStore = credentialStore.getKeychainStore(service: credentialStore.servicePrefix + self.relyingPartyId).keychainStore
        keychainStore.deleteAll()
        
        self.excludeConsentResult = nil
        self.createNewKeyConsentResult = nil
    }
    
    
    func test_01_perform_registration() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
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
    }
    
    
    func test_02_registration_timeout() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Nullify consent to cause delay
            self.createNewKeyConsentResult = nil
            //  Set timeout for 5 secs
            callback.timeout = 5000
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
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
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_03_reject_new_key_registration() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Reject operation
            self.createNewKeyConsentResult = .reject
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
            
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .cancelled:
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
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_04_missing_delegate() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = nil
            //  Reject operation
            self.createNewKeyConsentResult = .reject
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
            
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .cancelled:
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
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_05_unsupported_pub_key_cred() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set unsupported pub cred alg
            callback.pubCredAlg = [.rs256]
            //  Reject operation
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            let ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
            
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .unsupported:
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
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_06_excluded_credentials_consent() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Reject operation
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
            var ex = self.expectation(description: "WebAuthn Registration")
            callback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNotNil(webAuthnOutcome)
                result = webAuthnOutcome
                ex.fulfill()
            }) { (error) in
                XCTFail("Failed with unexpected error: \(error.localizedDescription)")
                ex.fulfill()
            }
            waitForExpectations(timeout: 60, handler: nil)
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, AuthenticatorData, and AttestedCredentialData to extract credentialId from WebAuthnOutcome
            guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult), let credentialData = attestationObj.authData.attestedCredentialData else {
                XCTFail("Failed to parse AuthenticatorData from WebAuthnOutcome result")
                return
            }
            
            //  https://www.w3.org/TR/webauthn/#op-make-cred 6.3.2.3 - confirms consent for excluded credentials
            let newCallback = try self.createRegistrationCallback()
            //  Add previously registered credentials as excluded credential
            newCallback.excludeCredentials = [credentialData.credentialId]
            //  Disable UV for testing
            newCallback.userVerification = .discouraged
            //  Set rpId
            newCallback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            newCallback.delegate = self
            //  Reject operation
            self.excludeConsentResult = .allow
            
            //  Perform registration with excludedCredentials
            ex = self.expectation(description: "WebAuthn Registration")
            newCallback.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
                ex.fulfill()
            }) { (error) in
            
                if let webAuthnError = error as? WebAuthnError {
                    switch webAuthnError {
                    case .invalidState:
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
            
            //  https://www.w3.org/TR/webauthn/#op-make-cred 6.3.2.3 - reject consent for excluded credentials
            let newCallback1 = try self.createRegistrationCallback()
            //  Add previously registered credentials as excluded credential
            newCallback1.excludeCredentials = [credentialData.credentialId]
            //  Disable UV for testing
            newCallback1.userVerification = .discouraged
            //  Set rpId
            newCallback1.relyingPartyId = self.relyingPartyId
            //  Set delegate
            newCallback1.delegate = self
            //  Reject operation
            self.excludeConsentResult = .reject
            
            //  Perform registration with excludedCredentials
            ex = self.expectation(description: "WebAuthn Registration")
            newCallback1.register(onSuccess: { (webAuthnOutcome) in
                XCTAssertNil(webAuthnOutcome)
                XCTFail("WebAuthnRegistration unexpectedly succeeded")
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
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_07_require_resident_key() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set requireResidentKey
            callback.requireResidentKey = true
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
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
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, AuthenticatorData, and AttestedCredentialData to extract credentialId from WebAuthnOutcome
            guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult), let credentialData = attestationObj.authData.attestedCredentialData else {
                XCTFail("Failed to parse AuthenticatorData from WebAuthnOutcome result")
                return
            }
            
            let credentialStore = KeychainCredentialStore()
            let userCredentials = credentialStore.lookupCredentialSource(rpId: self.relyingPartyId, credentialId: credentialData.credentialId)
            //  If requireResidentKey is true, PublicKeyCredentialSource must contain userHandle information so that it can be discoverable to the client
            XCTAssertNotNil(userCredentials)
            XCTAssertNotNil(userCredentials?.userHandle)
            
            //  Look up PublicKeyCredentialSource by rpId, and userHandle
            let userCredentialsByUserHandle = credentialStore.loadAllCredentialSources(rpId: self.relyingPartyId, userHandle: Bytes.fromString(callback.userId))
            XCTAssertNotNil(userCredentialsByUserHandle)
            XCTAssertEqual(userCredentialsByUserHandle.count, 1)
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_08_does_not_require_resident_key() {
        do {
            let callback = try self.createRegistrationCallback()
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set requireResidentKey
            callback.requireResidentKey = false
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
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
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, AuthenticatorData, and AttestedCredentialData to extract credentialId from WebAuthnOutcome
            guard let attestation = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult), let credentialData = attestation.authData.attestedCredentialData else {
                XCTFail("Failed to parse AuthenticatorData from WebAuthnOutcome result")
                return
            }
            
            let credentialStore = KeychainCredentialStore()
            let userCredentials = credentialStore.lookupCredentialSource(rpId: self.relyingPartyId, credentialId: credentialData.credentialId)
            //  If requireResidentKey is set to false, the userHandle of PublicKeyCredentialSource must be empty
            XCTAssertNotNil(userCredentials)
            XCTAssertNil(userCredentials?.userHandle)
            
            //  Look up PublicKeyCredentialSource with rpId, and userHandle, and make sure that there is no credential available
            let userCredentialsByUserHandle = credentialStore.loadAllCredentialSources(rpId: self.relyingPartyId, userHandle: Bytes.fromString(callback.userId))
            XCTAssertEqual(userCredentialsByUserHandle.count, 0)
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_09_webauthn_registration_with_attestation_none() {
        do {
            let callback = try self.createRegistrationCallback(attestationPreference: "none")
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set requireResidentKey
            callback.requireResidentKey = true
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
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
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, and AuthenciatorData to extract fmt from WebAuthnOutcome
            guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult) else {
                XCTFail("Failed to parse AttestationObject from WebAuthnOutcome result")
                return
            }
            
            XCTAssertEqual(attestationObj.fmt, "none")
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_10_webauthn_registration_with_attestation_indirect() {
        do {
            let callback = try self.createRegistrationCallback(attestationPreference: "indirect")
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set requireResidentKey
            callback.requireResidentKey = true
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
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
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, and AuthenciatorData to extract fmt from WebAuthnOutcome
            guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult) else {
                XCTFail("Failed to parse AttestationObject from WebAuthnOutcome result")
                return
            }
            
            XCTAssertEqual(attestationObj.fmt, "packed")
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
    }
    
    
    func test_11_webauthn_registration_with_attestation_direct() {
        do {
            let callback = try self.createRegistrationCallback(attestationPreference: "indirect")
            
            //  Disable UV for testing
            callback.userVerification = .discouraged
            //  Set rpId
            callback.relyingPartyId = self.relyingPartyId
            //  Set delegate
            callback.delegate = self
            //  Set requireResidentKey
            callback.requireResidentKey = true
            
            //  Set delegation consent result
            self.createNewKeyConsentResult = .allow
            
            //  Perform registration
            var result: String?
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
            
            guard let webAuthnResult = result else {
                XCTFail("Failed to capture the successful result")
                return
            }
            
            //  Parse AttestationObject, and AuthenciatorData to extract fmt from WebAuthnOutcome
            guard let attestationObj = self.parseAttestationObjectFromRegistrationResult(str: webAuthnResult) else {
                XCTFail("Failed to parse AttestationObject from WebAuthnOutcome result")
                return
            }
            
            XCTAssertEqual(attestationObj.fmt, "packed")
        }
        catch {
            XCTFail("Failed with unexpected error")
        }
    }
}


extension WebAuthnRegistrationTests: PlatformAuthenticatorRegistrationDelegate {
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
