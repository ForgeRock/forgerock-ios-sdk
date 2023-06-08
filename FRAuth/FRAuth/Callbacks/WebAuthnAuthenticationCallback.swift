// 
//  WebAuthnAuthenticationCallback.swift
//  FRAuth
//
//  Copyright (c) 2021-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit
import AuthenticationServices

/**
 WebAuthnAuthenticationCallback is a representation of AM's WebAuthn Authentication Node to generate WebAuthn assertion based on given credentials, and optionally set the WebAuthn outcome value in `Node`'s designated `HiddenValueCallback`
 */
open class WebAuthnAuthenticationCallback: WebAuthnCallback {
    
    //  MARK: - Public properties
    
    /// _type value in Callback response
    public var _type: String
    /// User Verification configuration value from Callback response
    public var userVerification: WAUserVerification
    /// Challenge string value from Callback response
    public var challenge: String
    /// Relying Party Identifier value from Callback response
    public var relyingPartyId: String
    /// Allowed credentials list of credential identifiers from Callback response
    public var allowCredentials: [[UInt8]]
    /// Timeout configuration value from Callback response
    public var timeout: Int
    /// Delegation to perform required user interaction while generating assertion
    public weak var delegate: PlatformAuthenticatorAuthenticationDelegate?
    
    
    //  MARK: - Private properties
    
    /// Internal WebAuthnClient to generate assertion
    var webAuthnClient: WebAuthnClient?
    /// Boolean indicator whether or not Callback response is AM 7.1.0 or above
    var isNewJSONFormat: Bool = false
    
    var successCallback: StringCompletionCallback?
    var errorCallback: ErrorCallback?
    var webAuthnManager: Any?
    
    //  MARK: - Lifecycle
    
    /// Initializes WebAuthnAuthenticationCallback from AM's `WebAuthn Authentication Node`JSON response
    /// - Parameter json: JSON response of `Callback`
    /// - Throws: `AuthError`for invalid `Callback` response
    public required init(json: [String : Any]) throws {
        
        //  Extract output attribute
        guard let outputs = json[CBConstants.output] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse("Failed to parse output")
        }
        
        guard let output = outputs.first, let name = output[CBConstants.name] as? String, name == CBConstants.data, let value = output[CBConstants.value] as? [String: Any] else {
            throw AuthError.invalidCallbackResponse("Failed to parse output")
        }
        
        //  Determine whether or not if response is from AM 7.1.0 or above
        if let action = value[CBConstants._action] as? String, action == CBConstants.webauthn_authentication {
            self.isNewJSONFormat = true
        }
        
        //  _type
        guard let _type = value[CBConstants._type] as? String else {
            throw AuthError.invalidCallbackResponse("Missing _type")
        }
        self._type = _type
        
        //  Challenge
        guard let challenge = value[CBConstants.challenge] as? String else {
            throw AuthError.invalidCallbackResponse("Missing challenge")
        }
        self.challenge = challenge
        
        //  Timeout
        guard let timeoutStr = value[CBConstants.timeout] as? String, let timeout = Int(timeoutStr) else {
            throw AuthError.invalidCallbackResponse("Missing timeout")
        }
        self.timeout = timeout
        
        //  User Verification
        guard let userVerificationStr = value[CBConstants.userVerification] as? String, let userVerification = WAUserVerification(rawValue: userVerificationStr) else {
            throw AuthError.invalidCallbackResponse("Missing userVerification")
        }
        self.userVerification = userVerification
        
        //  If AM 7.1.0 or above
        if self.isNewJSONFormat {
            //  Relying Party Identifier
            guard let relyingPartyId = value[CBConstants._relyingPartyId] as? String else {
                throw AuthError.invalidCallbackResponse("Missing relyingPartyId")
            }
            self.relyingPartyId = relyingPartyId
            
            //  Allow Credentials
            self.allowCredentials = []
            if let allowCredentials = value[CBConstants._allowCredentials] as? [[String: Any]] {
                for allowCredential in allowCredentials {
                    if let publicKeyId = allowCredential[CBConstants.id] as? [Int] {
                        var keyId: [Int8] = []
                        for byteInt in publicKeyId {
                            keyId.append(Int8(byteInt))
                        }
                        let uint8Arr = keyId.map { UInt8(bitPattern: $0) }
                        self.allowCredentials.append(uint8Arr)
                    }
                    else {
                        throw AuthError.invalidCallbackResponse("Invalid allowCredentials format")
                    }
                }
            }
            else {
                throw AuthError.invalidCallbackResponse("Missing allowCredentials")
            }
        }
        else {
            //  Relying Party Identifier
            guard let relyingPartyId = value[CBConstants.relyingPartyId] as? String else {
                throw AuthError.invalidCallbackResponse("Missing relyingPartyId")
            }
            
            if relyingPartyId.count > 0 {
                let rpIdSegments = relyingPartyId.split(separator: "\"")
                if rpIdSegments.count == 3, rpIdSegments.first == "rpId: " {
                    self.relyingPartyId = String(rpIdSegments[1])
                }
                else {
                    throw AuthError.invalidCallbackResponse("Invalid relying party identifier")
                }
            }
            else {
                self.relyingPartyId = ""
            }
            
            //  Allow Credentials
            guard let allowCredentialsStr = value[CBConstants.allowCredentials] as? String else {
                throw AuthError.invalidCallbackResponse("Missing allowCredentials")
            }
            let creds = WebAuthnCallback.convertInt8Arr(query: allowCredentialsStr)
            self.allowCredentials = []
            for cred in creds {
                var int8Arr: [Int8] = []
                let ints = cred.split(separator: ",")
                for int8 in ints {
                    let thisVal = int8.replacingOccurrences(of: " ", with: "")
                    if let int8Val = Int8(thisVal) {
                        int8Arr.append(int8Val)
                    }
                    else {
                        throw AuthError.invalidCallbackResponse("Invalid allowCredentials byte")
                    }
                }
                let uint8Arr = int8Arr.map { UInt8(bitPattern: $0) }
                self.allowCredentials.append(uint8Arr)
            }
        }
        
        try super.init(json: json)
        
        self.type = CallbackType.WebAuthnAuthenticationCallback.rawValue
    }
    
    
    //  MARK: - Public methods
    
    /// Authenticates against AM's `WebAuthn Authentication Node` based on the JSON callback and WebAuthn's properties within the Callback
    /// - Parameters:
    ///   - node: Optional `Node` object to set WebAuthn value to the designated `HiddenValueCallback`
    ///   - window: Optional `Window` set the presenting Window for the Apple Passkeys UI. If not set it will default to `UIApplication.shared.windows.first`
    ///   - preferImmediatelyAvailableCredentials: Optional `preferImmediatelyAvailableCredentials` set this to true if you want to use only local credentials. Default value `false`
    ///   - usePasskeysIfAvailable: Optional `usePasskeysIfAvailable` set this to enable Passkeys in supported devices (iOS 16+). Setting this to true will not affect older OSs
    ///   - onSuccess: Completion callback for successful WebAuthn assertion outcome; note that the outcome will automatically be set to the designated `HiddenValueCallback`
    ///   - onError: Error callback to notify any error thrown while generating WebAuthn assertion
    public func authenticate(node: Node? = nil, window: UIWindow? = UIApplication.shared.windows.first, preferImmediatelyAvailableCredentials: Bool = false, usePasskeysIfAvailable: Bool = false, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback) {
        if #available(iOS 16.0, *), usePasskeysIfAvailable {
            FRLog.i("Performing WebAuthn authentication using FRWebAuthnManager and Passkeys", subModule: WebAuthn.module)
            self.successCallback = onSuccess
            self.errorCallback = onError
            guard let window = window, let data = Data(base64Encoded: self.challenge, options: .ignoreUnknownCharacters), let node = node else {
                FRLog.e("The view was not in the app's view hierarchy!", subModule: WebAuthn.module)
                onError(FRWAKError.unknown(platformError: nil, message: "Failed to create PlatformAuthenticator"))
                return
            }
            self.webAuthnManager = FRWebAuthnManager(domain: self.relyingPartyId, authenticationAnchor: window, node: node)
            guard let webAuthnManager = self.webAuthnManager as? FRWebAuthnManager else { return }
            webAuthnManager.delegate = self
            
            webAuthnManager.signInWith(preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials, challenge: data, allowedCredentialsArray: self.allowCredentials, userVerificationPreference: self.convertUserVerification())
        } else {
            if self.isNewJSONFormat {
                FRLog.i("Performing WebAuthn authentication for AM 7.1.0 or above", subModule: WebAuthn.module)
            }
            else {
                FRLog.i("Performing WebAuthn authentication for AM 7.0.0 or below", subModule: WebAuthn.module)
            }
            
            guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                FRLog.e("Bundle Identifier is missing")
                onError(FRWAKError.unknown(platformError: nil, message: "Bundle Identifier is missing"))
                return
            }
            
            //  Platform Authenticator
            let platformAuthenticator = PlatformAuthenticator(authenticationDelegate: self)
            //  For AM 7.0.0, origin only supports https scheme; to be updated for AM 7.1.0
            var origin = CBConstants.originScheme + bundleIdentifier
            //  For AM 7.1.0 or above, origin should follow origin format according to FIDO AppId and Facet specification
            if self.isNewJSONFormat {
                origin = CBConstants.originPrefix + bundleIdentifier
            }
            
            let webAuthnClient = WebAuthnClient(origin: origin, authenticator: platformAuthenticator)
            self.webAuthnClient = webAuthnClient
            
            //  PublicKey credential request options
            var options = PublicKeyCredentialRequestOptions()
            
            //  Default userVerification option set to preferred
            options.userVerification = self.userVerification.convert()
            
            //  Challenge
            options.challenge = Bytes.fromString(self.challenge.urlSafeEncoding())
            //  Relying Party
            options.rpId = self.relyingPartyId
            //  Timeout
            options.timeout = UInt64(self.timeout/1000)
            
            //  Allowed credentials
            for allowCred in allowCredentials {
                options.addAllowCredential(credentialId: allowCred, transports: [.internal_])
            }
            
            webAuthnClient.get(options, onSuccess: { (assertion) in
                
                var result = "\(assertion.response.clientDataJSON)"
                
                let authInt8Arr = assertion.response.authenticatorData.map { Int8(bitPattern: $0) }
                let sigInt8Arr = assertion.response.signature.map { Int8(bitPattern: $0) }
                
                let authenticatorData = self.convertInt8ArrToStr(authInt8Arr)
                result = result + "::\(authenticatorData)"
                let signatureData = self.convertInt8ArrToStr(sigInt8Arr)
                result = result + "::\(signatureData)"
                result = result + "::\(assertion.id)"
                if let userHandle = assertion.response.userHandle {
                    let encoded = Base64.encodeBase64(userHandle)
                    if let decoded = encoded.base64Decoded() {
                        result = result + "::\(decoded)"
                    }
                }
                
                //  Expected AM result for successful assertion
                //  {clientDataJSON as String}::{Int8 array of authenticatorData}::{Int8 array of signature}::{assertion identifier}::{user handle}
                
                //  If Node is given, set WebAuthn outcome to designated HiddenValueCallback
                if let node = node {
                    FRLog.i("Found optional 'Node' instance, setting WebAuthn outcome to designated HiddenValueCallback", subModule: WebAuthn.module)
                    self.setWebAuthnOutcome(node: node, outcome: result)
                }
                
                if #available(iOS 16.0, *) {
                    FRLog.i("Local keypair exists and user authenticated locally succesfully. The device and FR SDK now supports Passkeys, in order to use it enable the functionality using `usePasskeysIfAvailable=true` and register a new keyPair.", subModule: WebAuthn.module)
                    self.delegate?.localKeyExistsAndPasskeysAreAvailable()
                }
                
                onSuccess(result)
                
            }) { (error) in
                
                /// Converts internal WAKError into WebAuthnError
                if let webAuthnError = error as? FRWAKError {
                    //  Converts the error to public facing error
                    let publicError = webAuthnError.convert()
                    if let node = node {
                        FRLog.i("Found optional 'Node' instance, setting WebAuthn error outcome to designated HiddenValueCallback", subModule: WebAuthn.module)
                        //  Converts WebAuthnError to proper WebAuthn error outcome that can be understood by AM
                        self.setWebAuthnOutcome(node: node, outcome: publicError.convertToWebAuthnOutcome())
                    }
                    onError(publicError)
                }
                else {
                    onError(error)
                }
            }
        }
    }
}

extension WebAuthnAuthenticationCallback: PlatformAuthenticatorAuthenticationDelegate {
    public func localKeyExistsAndPasskeysAreAvailable() { }
    
    public func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback) {
        if let delegate = self.delegate {
            FRLog.i("Found PlatformAuthenticatorAuthenticationDelegate, waiting for completion", subModule: WebAuthn.module)
            delegate.selectCredential(keyNames: keyNames, selectionCallback: selectionCallback)
        }
        else {
            FRLog.e("Missing PlatformAuthenticatorAuthenticationDelegate", subModule: WebAuthn.module)
        }
    }
}

extension WebAuthnAuthenticationCallback: FRWebAuthnManagerDelegate {
    // MARK: - WebAuthnManagerDelegate
    public func didFinishAuthorization() {
        self.successCallback?("Success")
    }
    
    public func didCompleteWithError(_ error: Error) {
        self.errorCallback?(error)
    }
    
    public func didCancelModalSheet() {
        self.successCallback?("Cancel")
    }
}

extension WebAuthnAuthenticationCallback {
    @available(iOS 15.0, *)
    fileprivate func convertUserVerification() -> ASAuthorizationPublicKeyCredentialUserVerificationPreference {
        let verificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference
        switch self.userVerification {
        case .preferred:
            verificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.preferred
        case .required:
            verificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.required
        case .discouraged:
            verificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference.discouraged
        }
        
        return verificationPreference
    }
}
