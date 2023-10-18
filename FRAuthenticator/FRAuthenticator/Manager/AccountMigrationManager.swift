//
//  AccountMigrationManager.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

public struct AccountMigrationManager {
    
    /// Decodes given OTPAauth Migration `URL` to `OathMechanism`s
    /// - Parameter url: OTPAauth Migration `URL` with otpauth-migration scheme
    /// - Returns: Array of `OathMechanism`s of types of hotp or totp
    /// - Throws: AccountMigrationError
    public static func decodeToMechanisms(url: URL) throws -> [OathMechanism] {
        let uriType = url.getURIType()
        let authType = url.getAuthType()
        
        guard uriType == .otpauthMigration else {
            FRALog.w("Unsupported scheme: \(String(describing: url.scheme))")
            throw AccountMigrationError.invalidScheme
        }
        
        guard authType == .offline else {
            FRALog.w("Unsupported host: \(String(describing: url.host))")
            throw AccountMigrationError.invalidHost
        }
        
        guard let data = url.valueOf("data") else {
            FRALog.w("Missing data parameter")
            throw AccountMigrationError.missingData
        }
        
        guard let decodedData = data.decodeBase64() else {
            FRALog.w("Cannot decode data")
            throw AccountMigrationError.failToDecodeData
        }
        
        let migrationPayload = try MigrationPayload(serializedData: decodedData)
        var mechanisms = [OathMechanism]()
        
        for otpParameter in migrationPayload.otpParameters {
            guard let secret: String = otpParameter.secret.base32Encode() else {
                continue
            }
            
            if otpParameter.type == .hotp {
                let hotpMechanism = HOTPMechanism(issuer: otpParameter.issuer, accountName: otpParameter.name, secret: secret , algorithm: otpParameter.algorithm.stringValue, counter:  Int(truncatingIfNeeded: otpParameter.counter), digits: otpParameter.digits.intValue)
                mechanisms.append(hotpMechanism)
            } else if otpParameter.type == .totp {
                let totpMechanism = TOTPMechanism(issuer: otpParameter.issuer, accountName: otpParameter.name, secret: secret, algorithm: otpParameter.algorithm.stringValue, digits: otpParameter.digits.intValue)
                mechanisms.append(totpMechanism)
            }
        }
        
        return mechanisms
    }
    
    
    /// Decodes given OTPAauth Migration `URL` to otpauth `URL`s
    /// - Parameter url: OTPAauth Migration `URL` with otpauth-migration scheme
    /// - Returns: Array of otpauth `URL` of types of hotp or totp
    /// - Throws: AccountMigrationError
    public static func decodeToURLs(url: URL) throws -> [URL] {
        let mechanisms: [OathMechanism] = try decodeToMechanisms(url: url)
        return mechanisms.compactMap { createUrl(mechanism: $0) }
    }
    
    
    /// Encodes given `OathMechanism`s into an OTPAauth Migration `URL`
    /// - Parameter mechanisms: Array of `OathMechanism`s of types of hotp or totp
    /// - Returns:  OTPAauth Migration `URL` with otpauth-migration scheme
    /// - Throws: BinaryEncodingError
    public static func encode(mechanisms: [OathMechanism]) throws -> URL? {
        var migrationPayload =  MigrationPayload()
        
        for mechanism in mechanisms {
            if mechanism.type != AuthType.hotp.rawValue && mechanism.type != AuthType.totp.rawValue {
                FRALog.w("Unsupported auth type \(mechanism.type), skipping the mechanism: \(mechanism.mechanismUUID)")
                continue
            }
            var otpParameters = MigrationPayload.OtpParameters()
            if let secret: Data =  mechanism.secret.base32Decode() {
                otpParameters.secret = secret
            } else {
                FRALog.w("Unable to decode secret, skipping the mechanism: \(mechanism.mechanismUUID)")
                continue
            }
            otpParameters.name = mechanism.accountName
            otpParameters.issuer = mechanism.issuer
            otpParameters.algorithm = MigrationPayload.Algorithm.valueFromString(value: mechanism.algorithm.rawValue)
            otpParameters.digits = MigrationPayload.DigitCount.valueFromInt(value: mechanism.digits)
            otpParameters.type = MigrationPayload.OtpType.valueFromString(value: mechanism.type)
            
            if let hotpMechanism = mechanism as? HOTPMechanism {
                otpParameters.counter = Int64(hotpMechanism.counter)
            }
            
            migrationPayload.otpParameters.append(otpParameters)
        }
        
        let data = try migrationPayload.serializedData()
        
        var components = URLComponents()
        components.scheme = URIType.otpauthMigration.rawValue
        components.host = AuthType.offline.rawValue
        components.queryItems = [ URLQueryItem(name: "data", value: data.base64EncodedString()) ]
        
        return components.url
    }
    
    
    /// Encodes given otpauth `URL`s into an OTPAauth Migration `URL`
    /// - Parameter urls: Array of otpauth `URL` of types of hotp or totp
    /// - Returns:  OTPAauth Migration `URL` with otpauth-migration scheme
    /// - Throws: BinaryEncodingError
    public static func encode(urls: [URL]) throws -> URL? {
        let mechanisms: [OathMechanism] = urls.compactMap { createMechanism(url:$0) }
        
        let uri: URL? = try encode(mechanisms: mechanisms)
        return uri
    }
    
    
    /// Constructs a URL for QR Code from  a given `OathMechanism`
    /// - Parameter mechanism: `OathMechanism` to be converted to url
    /// - Returns: QR Code `URL` from the mechanism
    static func createUrl(mechanism: OathMechanism) -> URL? {
        var components = URLComponents()
        components.scheme = URIType.otpauth.rawValue
        components.host = mechanism.type
        components.queryItems = [URLQueryItem(name: "secret", value: mechanism.secret),
                                 URLQueryItem(name: "digits", value: String(mechanism.digits)),
                                 URLQueryItem(name: "algorithm", value: mechanism.algorithm.rawValue)]
        
        if !mechanism.issuer.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "issuer", value: mechanism.issuer))
            components.path = "/\(mechanism.issuer):\(mechanism.accountName)"
        } else {
            components.path = "/\(mechanism.accountName)"
        }
        
        if let hotpMechanis = mechanism as? HOTPMechanism {
            components.queryItems?.append(URLQueryItem(name: "counter", value: String(hotpMechanis.counter)))
        } else if let totpMechanis = mechanism as? TOTPMechanism {
            components.queryItems?.append(URLQueryItem(name: "period", value: String(totpMechanis.period)))
        } else {
            FRALog.e("Unsupported type. Must be hotp or totp")
            return nil
        }
        
        return components.url
    }
    
    
    /// Static method to create an `OathMechanism` from `URL`. Doesn't store anything
    /// - Parameter url: `URL` of the QR Code
    /// - Returns: Newly Created OathMechanism of type hotp or totp. nil if can't create a mechanism
    public static func createMechanism(url: URL) -> OathMechanism? {
        let uriType = url.getURIType()
        let authType = url.getAuthType()
        
        guard uriType == .otpauth else {
            FRALog.e("The url scheme must be otpauth")
            return nil
        }
        
        guard  authType == .hotp || authType == .totp else {
            FRALog.e("The url host must be hotp or totp")
            return nil
        }
        
        guard let parser = try? OathQRCodeParser(url: url) else {
            FRALog.e("Could not parse the url")
            return nil
        }
        
        if authType == .hotp {
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
            FRALog.v("HOTPMechanism (\(mechanism.identifier) is created")
            return mechanism
        } else {
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            FRALog.v("TOTPMechanism (\(mechanism.identifier) is created")
            return mechanism
        }
    }
}


extension MigrationPayload.Algorithm {
    var stringValue: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .sha1:
            return "sha1"
        case .sha256:
            return "sha256"
        case .sha512:
            return "sha512"
        case .md5:
            return "md5"
        case .UNRECOGNIZED:
            return "UNRECOGNIZED"
        }
    }
    
    static func valueFromString(value: String) -> MigrationPayload.Algorithm {
        switch value {
        case "unspecified":
            return .unspecified
        case "sha1":
            return .sha1
        case "sha256":
            return .sha256
        case "sha512":
            return .sha512
        case "md5":
            return .md5
        default:
            return .UNRECOGNIZED(0)
        }
    }
}


extension MigrationPayload.DigitCount {
    var intValue: Int {
        switch self {
        case .unspecified:
            return -1
        case .six:
            return 6
        case .eight:
            return 8
        case .UNRECOGNIZED(let int):
            return int
        }
    }
    
    static func valueFromInt(value: Int) -> MigrationPayload.DigitCount {
        switch value {
        case -1:
            return .unspecified
        case 6:
            return .six
        case 8:
            return .eight
        default:
            return .UNRECOGNIZED(0)
        }
    }
}


extension MigrationPayload.OtpType {
    var stringValue: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .hotp:
            return "hotp"
        case .totp:
            return "totp"
        case .UNRECOGNIZED:
            return "UNRECOGNIZED"
        }
    }
    
    static func valueFromString(value: String) -> MigrationPayload.OtpType {
        switch value {
        case "unspecified":
            return .unspecified
        case "hotp":
            return .hotp
        case "totp":
            return .totp
        default:
            return .UNRECOGNIZED(0)
        }
    }
}
