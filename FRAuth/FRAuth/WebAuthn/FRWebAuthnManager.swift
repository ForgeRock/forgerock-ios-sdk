// 
//  FRWebAuthnManager.swift
//  FRAuth
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import AuthenticationServices
import Foundation
import os

public protocol FRWebAuthnManagerDelegate: NSObject {
    func didFinishAuthorization()
    func didCompleteWithError(_ error: Error)
    func didCancelModalSheet()
}

/**
 FRWebAuthnManager is a class handling WebAuthn Registation and Authentication using Apple's ASAuthorization libraries. Used by the SDK, it is called by the WebAuthnRegistration and WebAuthnAuthenticaton callbacks and sets the outcome in the HiddenValueCallback. This comes with the `FRWebAuthnManagerDelegate` that offers callbacks in the calling class for Success, Error and Cancel scenarios.
 */
@available(iOS 16, *)
public class FRWebAuthnManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    public weak var delegate: FRWebAuthnManagerDelegate?
    
    private var authenticationAnchor: ASPresentationAnchor?
    private var isPerformingModalReqest: Bool = false
    private var didTimeout: Bool = false
    private var node: Node
    private let domain: String
    private var deviceName: String?
    private var asAuthorizationController: ASAuthorizationController?
    
    public init(domain: String, authenticationAnchor: ASPresentationAnchor?, node: Node) {
        self.domain = domain
        self.authenticationAnchor = authenticationAnchor
        self.node = node
        super.init()
    }
    
    /// Sign In method, using AuthenticationServices. This will use the stored Passkeys to create the challenge and set it in tghe HiddenValue callback. Called by the WebAuthnAuthentication callback,
    /// by triggering the `func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)`
    /// delegate method.
    /// - Parameters:
    ///    - preferImmediatelyAvailableCredentials: set to `True` to use only local keys
    ///    - challenge: challenge `Data` as received from the Node
    ///    - allowedCredentialsArray: Allowed credentials
    
    public func signInWith(preferImmediatelyAvailableCredentials: Bool, challenge: Data, allowedCredentialsArray: [[UInt8]], userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference) {
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)

        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
        var credentialsArray: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] = []
        for credID in allowedCredentialsArray {
            credentialsArray.append(ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: Data(credID)))
        }
        assertionRequest.allowedCredentials = credentialsArray
        assertionRequest.userVerificationPreference = userVerificationPreference
        // Pass in any mix of supported sign-in request types.
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        self.setTimeout()
        if preferImmediatelyAvailableCredentials {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, no UI appears and
            // the system passes ASAuthorizationError.Code.canceled to call
            // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
            authController.performRequests(options: .preferImmediatelyAvailableCredentials)
        } else {
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
            // passkey from a nearby device.
            authController.performRequests()
        }
        self.asAuthorizationController = authController
        isPerformingModalReqest = true
    }
    
    /// Sign un method, using AuthenticationServices. This create the Passkey and store it in the Keychain,
    /// by triggering the `func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)`
    /// delegate method.
    /// - Parameters:
    ///    - userName: username
    ///    - challenge: challenge `Data` as received from the Node
    ///    - userID: userID
    ///    - deviceName: Optional device name. This will be the device name, that appears in the list of user devices
    public func signUpWith(userName: String, challenge: Data, userID: String, deviceName: String?, userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference, attestationPreference: ASAuthorizationPublicKeyCredentialAttestationKind) {
        self.deviceName = deviceName
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)

        // Fetch the challenge from the server. The challenge needs to be unique for each request.
        // The userID is the identifier for the user's account.
        //let challenge = Data()
        let userID = Data(userID.utf8)
        
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                                                name: userName, userID: userID)
        registrationRequest.userVerificationPreference = userVerificationPreference
        registrationRequest.attestationPreference = attestationPreference
        self.setTimeout()
        // Use only ASAuthorizationPlatformPublicKeyCredentialRegistrationRequests or
        // ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequests here.
        let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
    
        authController.performRequests()
        self.asAuthorizationController = authController
        isPerformingModalReqest = true
    }
    
    //MARK: - ASAuthorizationControllerPresentationContextProviding
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return authenticationAnchor!
    }
    
    //MARK: - ASAuthorizationControllerDelegate
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            FRLog.i("A new passkey was registered: \(credentialRegistration)")
            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            let int8Arr = credentialRegistration.rawAttestationObject?.bytes.map { Int8(bitPattern: $0) }
            let attestationObject = self.convertInt8ArrToStr(int8Arr!)
            
            let clientDataJSON = String(decoding: credentialRegistration.rawClientDataJSON, as: UTF8.self)
            
            let credID = base64ToBase64url(base64: credentialRegistration.credentialID.base64EncodedString())
            //  Expected AM result for successful attestation
            //  {clientDataJSON as String}::{attestation object in Int8 array}::{hashed credential identifier}
            let result: String
            if let unwrappedDeviceName = self.deviceName {
                result = "\(clientDataJSON)::\(attestationObject)::\(credID)::\(unwrappedDeviceName)"
            } else {
                result = "\(clientDataJSON)::\(attestationObject)::\(credID)"
            }
            // After the server verifies the registration and creates the user account, sign in the user with the new account.
            //didFinishSignIn()
            self.setWebAuthnOutcome(outcome: result)
            self.delegate?.didFinishAuthorization()
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            FRLog.i("A passkey was used to sign in: \(credentialAssertion)")
            // Verify the below signature and clientDataJSON with your service for the given userID.
            
            let signatureInt8 = credentialAssertion.signature.bytes.map { Int8(bitPattern: $0) }
            let signature = self.convertInt8ArrToStr(signatureInt8)
            let clientDataJSON = String(decoding: credentialAssertion.rawClientDataJSON, as: UTF8.self)
            let authenticatorDataInt8 = credentialAssertion.rawAuthenticatorData.bytes.map { Int8(bitPattern: $0) }
            let authenticatorData = self.convertInt8ArrToStr(authenticatorDataInt8)
            let credID = base64ToBase64url(base64: credentialAssertion.credentialID.base64EncodedString())
            let userIDString = String(decoding: credentialAssertion.userID, as: UTF8.self)
            //  Expected AM result for successful assertion
            
            //  {clientDataJSON as String}::{Int8 array of authenticatorData}::{Int8 array of signature}::{assertion identifier}::{user handle}
            let result = "\(clientDataJSON)::\(authenticatorData)::\(signature)::\(credID)::\(userIDString)"
            // After the server verifies the assertion, sign in the user.
            self.setWebAuthnOutcome(outcome: result)
            self.delegate?.didFinishAuthorization()
        default:
            let webAuthnError = FRWAKError.badData(platformError: nil, message: "Received unknown authorization type.")
            FRLog.e("Received unknown authorization type.")
            let publicError = webAuthnError.convert()
            self.setWebAuthnOutcome(outcome: publicError.convertToWebAuthnOutcome())
            self.delegate?.didCompleteWithError(publicError)
        }

        isPerformingModalReqest = false
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let authorizationError = error as? ASAuthorizationError else {
            isPerformingModalReqest = false
            FRLog.e("Unexpected authorization error: \(error.localizedDescription)")
            self.delegate?.didCompleteWithError(error)
            let webAuthnError = FRWAKError.unknown(platformError: error, message: error.localizedDescription)
            let publicError = webAuthnError.convert()
            self.setWebAuthnOutcome(outcome: publicError.convertToWebAuthnOutcome())
            return
        }
        FRLog.e("Error: \((error as NSError).userInfo)")
        let webAuthnError: FRWAKError
        switch authorizationError.code {
        case .canceled:
            if didTimeout {
                webAuthnError = FRWAKError.timeout(platformError: error, message: error.localizedDescription)
            } else {
                webAuthnError = FRWAKError.notAllowed(platformError: error, message: error.localizedDescription)
            }
            let publicErrorOutcome = webAuthnError.convert().convertToWebAuthnOutcome()
            self.setWebAuthnOutcome(outcome: publicErrorOutcome)
            self.delegate?.didCancelModalSheet()
            FRLog.i("Request canceled.")
            isPerformingModalReqest = false
            return
        case .unknown:
            webAuthnError = FRWAKError.unknown(platformError: error, message: error.localizedDescription)
        case .invalidResponse:
            webAuthnError = FRWAKError.notAllowed(platformError: error, message: error.localizedDescription)
        case .failed:
            webAuthnError = FRWAKError.notAllowed(platformError: error, message: error.localizedDescription)
        case .notHandled, .notInteractive:
            webAuthnError = FRWAKError.invalidState(platformError: error, message: error.localizedDescription)
        @unknown default:
            webAuthnError = FRWAKError.unknown(platformError: error, message: error.localizedDescription)
        }
        let publicError = webAuthnError.convert()
        self.setWebAuthnOutcome(outcome: publicError.convertToWebAuthnOutcome())
        self.delegate?.didCompleteWithError(error)
        isPerformingModalReqest = false
    }
    
    // MARK: - Private Methods
    private func setWebAuthnOutcome(outcome: String) {
        for callback in node.callbacks {
            if let hiddenValueCallback = callback as? HiddenValueCallback, hiddenValueCallback.isWebAuthnOutcome {
                hiddenValueCallback.setValue(outcome)
                return
            }
        }
    }
    
    private func convertInt8ArrToStr(_ arr: [Int8]) -> String {
        var str = ""
        for (index, byte) in arr.enumerated() {
            str = str + "\(byte)"
            if index != (arr.count - 1) {
                str = str + ","
            }
        }
        return str
    }
    
    private func base64ToBase64url(base64: String) -> String {
        let base64url = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64url
    }
    
    private func setTimeout() {
        self.didTimeout = false
        var timeoutInSec = 60
        for callback in node.callbacks {
            if let webAuthnCallback = callback as? WebAuthnRegistrationCallback {
                timeoutInSec = webAuthnCallback.timeout/1000
            }
            if let webAuthnCallback = callback as? WebAuthnAuthenticationCallback {
                timeoutInSec = webAuthnCallback.timeout/1000
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(timeoutInSec)) { [weak self] in
            if self?.isPerformingModalReqest == true {
                self?.didTimeout = true
                self?.asAuthorizationController?.cancel()
            }
        }
    }
}

fileprivate extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
