// 
//  WebAuthnRegistrationCallback.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/**
 WebAuthnRegistrationCallback is a representation of AM's WebAuthn Registration Node to generate WebAuthn attestation based on given credentials, and optionally set the WebAuthn outcome value in `Node`'s designated `HiddenValueCallback`
 */
open class WebAuthnRegistrationCallback: WebAuthnCallback {
    
    //  MARK: - Public properties
    
    /// _type value in Callback response
    public var _type: String
    /// Relying Party Name value from Callback response
    public var relyingPartyName: String
    /// Attestation Preference enum value from authenticatorSelection attribute of Callback response
    public var attestationPreference: WAAttestationPreference
    /// Display Name of the user from Callback response
    public var displayName: String
    /// Relying Party Identifier value from Callback response
    public var relyingPartyId: String
    /// Username of the user from Callback response
    public var userName: String
    /// User Identifier value from Callback response
    public var userId: String
    /// Timeout value from Callback response
    public var timeout: Int
    /// Excluded credentials list of credential identifiers from Callback response
    public var excludeCredentials: [[UInt8]]
    /// Public Key Credentials Parameters from Callback response
    public var pubKeyCredParams: [[String: Any]]
    /// Challenge string value from Callback response
    public var challenge: String
    /// User Verification enum value from Callback response
    public var userVerification: WAUserVerification
    /// Boolean indicator of Require Resident Key value from Callback response
    public var requireResidentKey: Bool
    /// Authenticator Attachment option value from authenticatorSelection attribute of Callback response
    public var authenticatorAttachment: WAAuthenticatorAttachment
    /// Delegation to perform required user interaction while generating assertion
    public weak var delegate: PlatformAuthenticatorRegistrationDelegate?
    
    
    //  MARK: - Private properties
    
    /// Internal WebAuthnClient to generate assertion
    var webAuthnClient: WebAuthnClient?
    /// Boolean indicator whether or not Callback response is AM 7.1.0 or above
    var isNewJSONFormat: Bool = false
    var pubCredAlg: [COSEAlgorithmIdentifier] = []
    
    //  MARK: - Lifecycle
    
    /// Initializes WebAuthnRegistrationCallback from AM's `WebAuthn Registration Node` JSON response
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
        if let action = value[CBConstants._action] as? String, action == CBConstants.webauthn_registration {
            self.isNewJSONFormat = true
        }
        
        //  Relying Party Name
        guard let relyingPartyName = value[CBConstants.relyingPartyName] as? String else {
            throw AuthError.invalidCallbackResponse("Missing relyingPartyName")
        }
        self.relyingPartyName = relyingPartyName
        
        //  Attestation Preference
        guard let attestationPreferenceStr = value[CBConstants.attestationPreference] as? String, let attestationPreference = WAAttestationPreference(rawValue: attestationPreferenceStr) else {
            throw AuthError.invalidCallbackResponse("Missing attestationPreference")
        }
        self.attestationPreference = attestationPreference
        
        //  Display Name
        guard let displayName = value[CBConstants.displayName] as? String else {
            throw AuthError.invalidCallbackResponse("Missing displayName")
        }
        self.displayName = displayName
        
        //  Username
        guard let userName = value[CBConstants.userName] as? String else {
            throw AuthError.invalidCallbackResponse("Missing userName")
        }
        self.userName = userName
        
        //  User Identifier
        guard let userId = value[CBConstants.userId] as? String else {
            throw AuthError.invalidCallbackResponse("Missing userId")
        }
        self.userId = userId
        
        //  type; must be WebAuthn
        guard let _type = value[CBConstants._type] as? String else {
            throw AuthError.invalidCallbackResponse("Missing or invalid _type")
        }
        self._type = _type
        
        //  Timeout
        guard let timeoutStr = value[CBConstants.timeout] as? String, let timeout = Int(timeoutStr) else {
            throw AuthError.invalidCallbackResponse("Missing timeout")
        }
        self.timeout = timeout
        
        //  Challenge
        guard let challenge = value[CBConstants.challenge] as? String else {
            throw AuthError.invalidCallbackResponse("Missing challenge")
        }
        self.challenge = challenge
        
        //  If AM 7.1.0 or above
        if self.isNewJSONFormat {
            
            //  Relying Party Id
            guard let relyingPartyId = value[CBConstants._relyingPartyId] as? String else {
                throw AuthError.invalidCallbackResponse("Missing relyingPartyId")
            }
            self.relyingPartyId = relyingPartyId
            
            //  Authenticator Selection
            guard let authenticatorSelection = value[CBConstants._authenticatorSelection] as? [String: Any] else {
                throw AuthError.invalidCallbackResponse("Missing authenticatorSelection")
            }
            
            self.requireResidentKey = false
            self.userVerification = .preferred
            self.authenticatorAttachment = .unspecified
            
            if let requireResidentKey = authenticatorSelection[CBConstants.requireResidentKey] as? Bool {
                self.requireResidentKey = requireResidentKey
            }
            if let userVerificationStr = authenticatorSelection[CBConstants.userVerification] as? String, let userVerification = WAUserVerification(rawValue: userVerificationStr) {
                self.userVerification = userVerification
            }
            if let authenticatorAttachmentStr = authenticatorSelection[CBConstants.authenticatorAttachment] as? String, let authenticatorAttachment = WAAuthenticatorAttachment(rawValue: authenticatorAttachmentStr) {
                guard authenticatorAttachment != .crossPlatform else {
                    throw AuthError.invalidCallbackResponse("Unsupported Authenticator Attachment type")
                }
                self.authenticatorAttachment = authenticatorAttachment
            }
            
            // Exclude Credentials
            self.excludeCredentials = []
            if let excludeCredentials = value[CBConstants._excludeCredentials] as? [[String: Any]] {
                for excludeCredential in excludeCredentials {
                    if let publicKeyId = excludeCredential[CBConstants.id] as? [Int] {
                        var keyId: [Int8] = []
                        for byteInt in publicKeyId {
                            keyId.append(Int8(byteInt))
                        }
                        let uint8Arr = keyId.map { UInt8(bitPattern: $0) }
                        self.excludeCredentials.append(uint8Arr)
                    }
                    else {
                        throw AuthError.invalidCallbackResponse("Invalid excludeCredentials byte")
                    }
                }
            }
            
            //  Public Key Credentials Parameters
            guard let pubKeyCredParams = value[CBConstants._pubKeyCredParams] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse("Invalid pubKeyCredParams format")
            }
            
            for pubKeyCred in pubKeyCredParams {
                guard let type = pubKeyCred[CBConstants.type] as? String, type == CBConstants.public_key, let alg = pubKeyCred[CBConstants.alg] as? Int, let coseAlg = COSEAlgorithmIdentifier.fromInt(alg) else {
                    throw AuthError.invalidCallbackResponse("Invalid pubKeyCredParams format")
                }
                self.pubCredAlg.append(coseAlg)
            }
            self.pubKeyCredParams = pubKeyCredParams
        }
        //  For AM 7.0.0 and below
        else {
            
            //  Relying Party Id
            guard let relyingPartyId = value[CBConstants.relyingPartyId] as? String else {
                throw AuthError.invalidCallbackResponse("Missing relyingPartyId")
            }
            
            if relyingPartyId.count > 0 {
                let rpIdSegments = relyingPartyId.split(separator: "\"")
                if rpIdSegments.count == 3, rpIdSegments.first == "id: " {
                    self.relyingPartyId = String(rpIdSegments[1])
                }
                else {
                    throw AuthError.invalidCallbackResponse("Invalid relying party identifier")
                }
            }
            else {
                self.relyingPartyId = ""
            }
            
            //  Authenticator Selection
            guard let authenticatorSelection = value[CBConstants.authenticatorSelection] as? String else {
                throw AuthError.invalidCallbackResponse("Missing authenticatorSelection")
            }
            
            self.requireResidentKey = false
            self.userVerification = .preferred
            self.authenticatorAttachment = .unspecified
            
            if let jsonData = try? JSONSerialization.jsonObject(with: authenticatorSelection.data(using: .utf8) ?? Data(), options: []) as? [String: Any] {
                
                if let requireResidentKey = jsonData[CBConstants.requireResidentKey] as? Bool {
                    self.requireResidentKey = requireResidentKey
                }
                if let userVerificationStr = jsonData[CBConstants.userVerification] as? String, let userVerification = WAUserVerification(rawValue: userVerificationStr) {
                    self.userVerification = userVerification
                }
                if let authenticatorAttachmentStr = jsonData[CBConstants.authenticatorAttachment] as? String, let authenticatorAttachment = WAAuthenticatorAttachment(rawValue:authenticatorAttachmentStr) {
                    guard authenticatorAttachment != .crossPlatform else {
                        throw AuthError.invalidCallbackResponse("Unsupported Authenticator Attachment type")
                    }
                    self.authenticatorAttachment = authenticatorAttachment
                }
            }
            
            // Exclude Credentials
            self.excludeCredentials = []
            if let excludedCredentialsStr = value[CBConstants.excludeCredentials] as? String {
                let excludedCreds = WebAuthnCallback.convertInt8Arr(query: excludedCredentialsStr)
                for cred in excludedCreds {
                    var int8Arr: [Int8] = []
                    let ints = cred.split(separator: ",")
                    for int8 in ints {
                        let thisVal = int8.replacingOccurrences(of: " ", with: "")
                        if let int8Val = Int8(thisVal) {
                            int8Arr.append(int8Val)
                        }
                        else {
                            throw AuthError.invalidCallbackResponse("Invalid excludeCredentials byte")
                        }
                    }
                    let uint8Arr = int8Arr.map { UInt8(bitPattern: $0) }
                    self.excludeCredentials.append(uint8Arr)
                }
            }
            
            //  Public Key Credentials Parameters
            guard let pubKeyCredParamsStr = value[CBConstants.pubKeyCredParams] as? String, let pubKeyCredParams = try? JSONSerialization.jsonObject(with: pubKeyCredParamsStr.data(using: .utf8) ?? Data(), options: []) as? [[String: Any]], pubKeyCredParams.isEmpty == false else {
                throw AuthError.invalidCallbackResponse("Missing pubKeyCredParams")
            }
            
            for pubKeyCred in pubKeyCredParams {
                guard let type = pubKeyCred[CBConstants.type] as? String, type == CBConstants.public_key, let alg = pubKeyCred[CBConstants.alg] as? Int, let coseAlg = COSEAlgorithmIdentifier.fromInt(alg) else {
                    throw AuthError.invalidCallbackResponse("Invalid pubKeyCredParams format")
                }
                self.pubCredAlg.append(coseAlg)
            }
            self.pubKeyCredParams = pubKeyCredParams
        }
        
        try super.init(json: json)
        
        self.type = CallbackType.WebAuthnRegistrationCallback.rawValue
    }
    
    
    //  MARK: - Public methods
    
    /// Registers against AM's `WebAuthn Registration Node` based on the JSON callback and WebAuthn's properties within the Callback
    /// - Parameters:
    ///   - node: Optional `Node` object to set WebAuthn value to the designated `HiddenValueCallback`
    ///   - onSuccess: Completion callback for successful WebAuthn assertion outcome; note that the outcome will automatically be set to the designated `HiddenValueCallback`
    ///   - onError: Error callback to notify any error thrown while generating WebAuthn assertion
    public func register(node: Node? = nil, onSuccess: @escaping StringCompletionCallback, onError: @escaping ErrorCallback) {
        
        if self.isNewJSONFormat {
            FRLog.i("Performing WebAuthn registration for AM 7.1.0 or above", subModule: WebAuthn.module)
        }
        else {
            FRLog.i("Performing WebAuthn registration for AM 7.0.0 or below", subModule: WebAuthn.module)
        }
        
        //  Platform Authenticator
        let platformAuthenticator = PlatformAuthenticator(registrationDelegate: self)
        //  For AM 7.0.0, origin only supports https scheme; to be updated for AM 7.1.0
        var origin = CBConstants.originScheme + (Bundle.main.bundleIdentifier ?? CBConstants.defaultOrigin)
        //  For AM 7.1.0 or above, origin should follow origin format according to FIDO AppId and Facet specification
        if self.isNewJSONFormat {
            origin = CBConstants.originPrefix + (Bundle.main.bundleIdentifier ?? CBConstants.defaultOrigin)
        }
        let webAuthnClient = WebAuthnClient(origin: origin, authenticator: platformAuthenticator)
        self.webAuthnClient = webAuthnClient
        
        //  Default UserVerification set to preferred
        let userVerification = self.userVerification.convert()
        
        //  PublicKey credential creation options
        var options = PublicKeyCredentialCreationOptions()
        //  Challenge
        options.challenge = Bytes.fromString(self.challenge.urlSafeEncoding())
        //  User
        options.user.id = Bytes.fromString(self.userId)
        options.user.name = self.userName
        options.user.displayName = self.displayName
        //  Relying Party
        options.rp.id = self.relyingPartyId
        options.rp.name = self.relyingPartyName
        //  Timeout
        options.timeout = UInt64(self.timeout/1000)
        
        //  Default attestation to none
        options.attestation = self.attestationPreference.convert()
        
        //  PublicKey credential parameters
        for alg in self.pubCredAlg {
            options.addPubKeyCredParam(alg: alg)
        }
        
        //  Exclude credentials with PublicKeyCredentialDescriptor
        for excludedCred in self.excludeCredentials {
            //  Do not define transport due to a bug in ClientCreateOperation.swift#241 as per https://www.w3.org/TR/webauthn/#op-make-cred 6.3.2.3
            //  As long as the given credentials is known to Authenticator, the client should trigger the authorization gesture regardless of the transport
            let excludeCredentialDescriptor = PublicKeyCredentialDescriptor(id: excludedCred, transports: [])
            options.excludeCredentials.append(excludeCredentialDescriptor)
        }
        
        //  Authenticator selection
        options.authenticatorSelection = AuthenticatorSelectionCriteria(requireResidentKey: self.requireResidentKey, userVerification: userVerification)

        //  Perfrom credential create operation through WebAuthnClient
        webAuthnClient.create(options, onSuccess: { (credential) in
        
            let int8Arr = credential.response.attestationObject.map { Int8(bitPattern: $0) }
            let attObj = self.convertInt8ArrToStr(int8Arr)
            //  Expected AM result for successful attestation
            //  {clientDataJSON as String}::{attestation object in Int8 array}::{hashed credential identifier}
            let result = "\(credential.response.clientDataJSON)::\(attObj)::\(credential.id)"
            
            //  If Node is given, set WebAuthn outcome to designated HiddenValueCallback
            if let node = node {
                FRLog.i("Found optional 'Node' instance, setting WebAuthn outcome to designated HiddenValueCallback", subModule: WebAuthn.module)
                self.setWebAuthnOutcome(node: node, outcome: result)
            }
            onSuccess(result)
            
        }) { (error) in
        
            /// Converts internal WAKError into WebAuthnError
            if let webAuthnError = error as? WAKError {
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


extension WebAuthnRegistrationCallback: PlatformAuthenticatorRegistrationDelegate {
    public func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        
        if let delegate = self.delegate {
            FRLog.i("Found PlatformAuthenticatorRegistrationDelegate, waiting for completion", subModule: WebAuthn.module)
            delegate.excludeCredentialDescriptorConsent(consentCallback: consentCallback)
        }
        else {
            FRLog.e("Missing PlatformAuthenticatorRegistrationDelegate", subModule: WebAuthn.module)
            consentCallback(.reject)
        }
    }
    
    public func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        
        if let delegate = self.delegate {
            FRLog.i("Found PlatformAuthenticatorRegistrationDelegate, waiting for completion", subModule: WebAuthn.module)
            delegate.createNewCredentialConsent(keyName: keyName, rpName: rpName, rpId: rpId, userName: userName, userDisplayName: userDisplayName, consentCallback: consentCallback)
        }
        else {
            FRLog.e("Missing PlatformAuthenticatorRegistrationDelegate", subModule: WebAuthn.module)
            consentCallback(.reject)
        }
    }
}
