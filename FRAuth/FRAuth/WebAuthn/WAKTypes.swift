//
//  WAKTypes.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021-2022 ForgeRock, Inc.
//

import Foundation

enum FRWAKError: Error {
    case badData(platformError: Error?, message: String?)
    case badOperation(platformError: Error?, message: String?)
    case invalidState(platformError: Error?, message: String?)
    case constraint(platformError: Error?, message: String?)
    case cancelled(platformError: Error?, message: String?)
    case timeout(platformError: Error?, message: String?)
    case notAllowed(platformError: Error?, message: String?)
    case unsupported(platformError: Error?, message: String?)
    case unknown(platformError: Error?, message: String?)
    
    func platformError() -> Error? {
        switch self {
        case .badData(platformError: let platformError, message: _),
                .badOperation(platformError: let platformError, message: _),
                .invalidState(platformError: let platformError, message: _),
                .constraint(platformError: let platformError, message: _),
                .cancelled(platformError: let platformError, message: _),
                .timeout(platformError: let platformError, message: _),
                .notAllowed(platformError: let platformError, message: _),
                .unsupported(platformError: let platformError, message: _),
                .unknown(platformError: let platformError, message: _):
            return platformError
        }
    }
    
    func message() -> String? {
        switch self {
        case .badData(platformError: _, message: let message),
                .badOperation(platformError: _, message: let message),
                .invalidState(platformError: _, message: let message),
                .constraint(platformError: _, message: let message),
                .cancelled(platformError: _, message: let message),
                .timeout(platformError: _, message: let message),
                .notAllowed(platformError: _, message: let message),
                .unsupported(platformError: _, message: let message),
                .unknown(platformError: _, message: let message):
            return message
        }
    }
}

enum WAKResult<T, Error: Swift.Error> {
    case success(T)
    case failure(Error)
}

enum PublicKeyCredentialType: String, Codable {
    case publicKey = "public-key"
}

enum UserVerificationRequirement: String, Codable {

    case required
    case preferred
    case discouraged

    static func ==(
        lhs: UserVerificationRequirement,
        rhs: UserVerificationRequirement) -> Bool {

        switch (lhs, rhs) {
        case (.required, .required):
            return true
        case (.preferred, .preferred):
            return true
        case (.discouraged, .discouraged):
            return true
        default:
            return false
        }

    }
}

protocol AuthenticatorResponse : Codable {}
struct AuthenticatorAttestationResponse : AuthenticatorResponse {
    var clientDataJSON: String
    var attestationObject: [UInt8]
}

struct AuthenticatorAssertionResponse: AuthenticatorResponse {
    var clientDataJSON: String
    var authenticatorData: [UInt8]
    var signature: [UInt8]
    var userHandle: [UInt8]?
}

struct PublicKeyCredential<T: AuthenticatorResponse>: Codable {
    var type: PublicKeyCredentialType = .publicKey
    var rawId: [UInt8]
    var id: String
    var response: T
    // getClientExtensionResults()
    
    func toJSON() -> Optional<String> {
       return JSONHelper<PublicKeyCredential<T>>.encode(self)
    }
}

enum AuthenticatorTransport: String, Codable, Equatable {
    case usb
    case nfc
    case ble
    case internal_ = "internal"

    static func ==(
        lhs: AuthenticatorTransport,
        rhs: AuthenticatorTransport) -> Bool {

        switch (lhs, rhs) {
        case (.usb, .usb):
            return true
        case (.nfc, .nfc):
            return true
        case (.ble, .ble):
            return true
        case (.internal_, .internal_):
            return true
        default:
            return false
        }
    }
}

struct PublicKeyCredentialDescriptor: Codable {
    
    var type: PublicKeyCredentialType = .publicKey
    var id: [UInt8] // credential ID
    var transports: [AuthenticatorTransport]
    
    init(
        id:         [UInt8]                  = [UInt8](),
        transports: [AuthenticatorTransport] = [AuthenticatorTransport]()
    ) {
        self.id         = id
        self.transports = transports
    }

    mutating func addTransport(transport: AuthenticatorTransport) {
       self.transports.append(transport)
    }
}

struct PublicKeyCredentialRpEntity: Codable {
    
    var id: String?
    var name: String
    var icon: String?
    
    init(
        id: String? = nil,
        name: String = "",
        icon: String? = nil
    ) {
        self.id   = id
        self.name = name
        self.icon = icon
    }
}

struct PublicKeyCredentialUserEntity: Codable {
    
    var id: [UInt8]
    var displayName: String
    var name: String
    var icon: String?
    
    init(
        id: [UInt8] = [UInt8](),
        displayName: String = "",
        name: String = "",
        icon: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.name = name
        self.icon = icon
    }
}

enum AttestationConveyancePreference: String, Codable {
    case none
    case direct
    case indirect

    static func ==(
        lhs: AttestationConveyancePreference,
        rhs: AttestationConveyancePreference) -> Bool {

        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.direct, .direct):
            return true
        case (.indirect, .indirect):
            return true
        default:
            return false
        }
    }
}

struct PublicKeyCredentialParameters : Codable {
    var type: PublicKeyCredentialType = .publicKey
    var alg: COSEAlgorithmIdentifier
    
    init(alg: COSEAlgorithmIdentifier) {
        self.alg = alg
    }
}

enum TokenBindingStatus: String, Codable {

    case present
    case supported

    static func ==(
        lhs: TokenBindingStatus,
        rhs: TokenBindingStatus) -> Bool{

        switch (lhs, rhs) {
        case (.present, .present):
            return true
        case (.supported, .supported):
            return true
        default:
            return false
        }
    }
}

struct TokenBinding: Codable {
    var status: TokenBindingStatus
    var id: String
    
    init(id: String, status: TokenBindingStatus) {
        self.id = id
        self.status = status
    }
}

enum CollectedClientDataType: String, Codable {
    case webAuthnCreate = "webauthn.create"
    case webAuthnGet = "webauthn.get"
}

struct CollectedClientData : Codable {
    var type: CollectedClientDataType
    var challenge: String
    var origin: String
    var tokenBinding: TokenBinding?
}

enum AuthenticatorAttachment: String, Codable {
    case platform
    case crossPlatform = "cross-platform"

    static func ==(
        lhs: AuthenticatorAttachment,
        rhs: AuthenticatorAttachment) -> Bool {
        switch (lhs, rhs) {
        case (.platform, .platform):
            return true
        case (.crossPlatform, .crossPlatform):
            return true
        default:
            return false
        }
    }
}

struct AuthenticatorSelectionCriteria: Codable {
    
    var authenticatorAttachment: AuthenticatorAttachment?
    var requireResidentKey: Bool
    var userVerification: UserVerificationRequirement
    
    init(
        authenticatorAttachment: AuthenticatorAttachment? = nil,
        requireResidentKey: Bool = true,
        userVerification: UserVerificationRequirement = .preferred
    ) {
        self.authenticatorAttachment = authenticatorAttachment
        self.requireResidentKey = requireResidentKey
        self.userVerification = userVerification
    }
}

// put extensions supported in this library
struct ExtensionOptions: Codable {

}

struct PublicKeyCredentialCreationOptions: Codable {
    
    var rp: PublicKeyCredentialRpEntity
    var user: PublicKeyCredentialUserEntity
    var challenge: [UInt8]
    var pubKeyCredParams: [PublicKeyCredentialParameters]
    var timeout: UInt64?
    var excludeCredentials: [PublicKeyCredentialDescriptor]
    var authenticatorSelection: AuthenticatorSelectionCriteria?
    var attestation: AttestationConveyancePreference
    var extensions: ExtensionOptions?
    
    init(
        rp: PublicKeyCredentialRpEntity = PublicKeyCredentialRpEntity(),
        user: PublicKeyCredentialUserEntity = PublicKeyCredentialUserEntity(),
        challenge: [UInt8] = [UInt8](),
        pubKeyCredParams: [PublicKeyCredentialParameters] = [PublicKeyCredentialParameters](),
        timeout: UInt64? = nil,
        excludeCredentials: [PublicKeyCredentialDescriptor] = [PublicKeyCredentialDescriptor](),
        authenticatorSelection: AuthenticatorSelectionCriteria? = nil,
        attestation: AttestationConveyancePreference = .none
    ) {
        self.rp = rp
        self.user = user
        self.challenge = challenge
        self.pubKeyCredParams = pubKeyCredParams
        self.timeout = timeout
        self.excludeCredentials = excludeCredentials
        self.authenticatorSelection = authenticatorSelection
        self.attestation = attestation
        // not supported yet
        self.extensions = nil
    }
    
    mutating func addPubKeyCredParam(alg: COSEAlgorithmIdentifier) {
        self.pubKeyCredParams.append(PublicKeyCredentialParameters(alg: alg))
    }
    
    func toJSON() -> Optional<String> {
        let obj = PublicKeyCredentialCreationArgs(publicKey: self)
        return JSONHelper<PublicKeyCredentialCreationArgs>.encode(obj)
    }
    
    static func fromJSON(json: String) -> Optional<PublicKeyCredentialCreationOptions> {
        guard let args = JSONHelper<PublicKeyCredentialCreationArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

struct PublicKeyCredentialRequestOptions: Codable {
    var challenge: [UInt8]
    var rpId: String?
    var allowCredentials: [PublicKeyCredentialDescriptor]
    var userVerification: UserVerificationRequirement
    var timeout: UInt64?
    // let extensions: []
    
    init(
        challenge: [UInt8] = [UInt8](),
        rpId: String = "",
        allowCredentials: [PublicKeyCredentialDescriptor] = [PublicKeyCredentialDescriptor](),
        userVerification: UserVerificationRequirement = .preferred,
        timeout: UInt64? = nil
    ) {
        self.challenge = challenge
        self.rpId = rpId
        self.allowCredentials = allowCredentials
        self.userVerification = userVerification
        self.timeout = timeout
    }
    
    mutating func addAllowCredential(
        credentialId: [UInt8],
        transports: [AuthenticatorTransport]
    ) {
        self.allowCredentials.append(PublicKeyCredentialDescriptor(
            id:         credentialId,
            transports: transports
        ))
    }
    
    func toJSON() -> Optional<String> {
        let obj = PublicKeyCredentialRequestArgs(publicKey: self)
        return JSONHelper<PublicKeyCredentialRequestArgs>.encode(obj)
    }
    
    static func fromJSON(json: String) -> Optional<PublicKeyCredentialRequestOptions> {
        guard let args = JSONHelper<PublicKeyCredentialRequestArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

struct PublicKeyCredentialCreationArgs: Codable {
    let publicKey: PublicKeyCredentialCreationOptions
}

struct PublicKeyCredentialRequestArgs: Codable {
    let publicKey: PublicKeyCredentialRequestOptions
}
