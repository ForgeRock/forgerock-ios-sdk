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

/// AccountMigrationManager provides static methods for conveniently encoding to and decoding from otp accounts migration URL (QR Code)
public struct AccountMigrationManager {
    
    /// Decodes given OTPAuth Migration `URL` to `Account`s
    /// - Parameter url: OTPAuth Migration `URL` with otpauth-migration scheme
    /// - Returns: Array of `Account`s decoded from the migration url
    /// - Throws: AccountMigrationError
    public static func decodeToAccounts(url: URL) throws -> [Account] {
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
        var accounts = [Account]()
        
        for otpParameter in migrationPayload.otpParameters {
            guard let secret: String = otpParameter.secret.base32Encode() else {
                continue
            }
            let account = Account(issuer: otpParameter.issuer, accountName: otpParameter.name)
            account.imageUrl = otpParameter.image == "" ? nil : otpParameter.image.urlSafeDecoding().base64Decoded()
            if otpParameter.type == .hotp {
                let hotpMechanism = HOTPMechanism(issuer: otpParameter.issuer, accountName: otpParameter.name, secret: secret , algorithm: otpParameter.algorithm.stringValue, counter:  Int(truncatingIfNeeded: otpParameter.counter), digits: otpParameter.digits.intValue)
                account.mechanisms.append(hotpMechanism)
            } else if otpParameter.type == .totp {
                let period = otpParameter.period == 0 ? nil : Int(truncatingIfNeeded:otpParameter.period)
                let totpMechanism = TOTPMechanism(issuer: otpParameter.issuer, accountName: otpParameter.name, secret: secret, algorithm: otpParameter.algorithm.stringValue, period: period, digits: otpParameter.digits.intValue)
                account.mechanisms.append(totpMechanism)
            }
            accounts.append(account)
        }
        
        return accounts
    }
    
    
    /// Decodes given OTPAuth Migration `URL` to otpauth `URL`s
    /// - Parameter url: OTPAuth Migration `URL` with otpauth-migration scheme
    /// - Returns: Array of otpauth `URL` of types of hotp or totp
    /// - Throws: AccountMigrationError
    public static func decodeToURLs(url: URL) throws -> [URL] {
        let accounts: [Account] = try decodeToAccounts(url: url)
        return accounts.map{ createUrls(account: $0) }.flatMap { $0 }
    }
    
    
    /// Encodes given `Account`s into an OTPAuth Migration `URL`
    /// For an array of more than 10 items the returned URL might be too long when generating a QR Code. In this case generating multiple migration urls(QR codes) is advised
    /// - Parameter accounts: Array of `Account`s to be incoded into a migration url
    /// - Returns:  OTPAuth Migration `URL` with otpauth-migration scheme
    /// - Throws: BinaryEncodingError
    public static func encode(accounts: [Account]) throws -> URL? {
        var migrationPayload =  MigrationPayload()
        
        for account in accounts {
            let mechanisms = account.mechanisms.compactMap{ $0 as? OathMechanism }
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
                otpParameters.image = account.imageUrl?.base64URLSafeEncoded() ?? ""
                
                if let hotpMechanism = mechanism as? HOTPMechanism {
                    otpParameters.counter = Int64(hotpMechanism.counter)
                } else if let totpMechanism = mechanism as? TOTPMechanism {
                    otpParameters.period = Int64(totpMechanism.period)
                }
                
                migrationPayload.otpParameters.append(otpParameters)
            }
        }
        
        let data = try migrationPayload.serializedData()
        
        var components = URLComponents()
        components.scheme = URIType.otpauthMigration.rawValue
        components.host = AuthType.offline.rawValue
        components.queryItems = [ URLQueryItem(name: "data", value: data.base64EncodedString()) ]
        
        return components.url
    }
    
    
    /// Encodes given otpauth `URL`s into an OTPAuth Migration `URL`.
    /// For an array of more than 10 items the returned URL might be too long when generating a QR Code. In this case generating multiple migration urls(QR codes) is advised
    /// - Parameter urls: Array of otpauth `URL` of types of hotp or totp.
    /// - Returns:  OTPAuth Migration `URL` with otpauth-migration scheme
    /// - Throws: BinaryEncodingError
    public static func encode(urls: [URL]) throws -> URL? {
        let accounts: [Account] = urls.compactMap { createAccount(url:$0) }
        
        let uri: URL? = try encode(accounts: accounts)
        return uri
    }
    
    
    /// Constructs an array of  QR Code URLs for the given account's mechanisms
    /// - Parameter account: the `Account` to be converted to url
    /// - Returns: an array of URLs for the given account's mechanisms
    static func createUrls(account: Account) -> [URL] {
        let otpMechanisms: [OathMechanism] = account.mechanisms.compactMap{ $0 as? OathMechanism }
        return otpMechanisms.compactMap { createUrl(mechanism: $0, imageUrl: account.imageUrl)}
    }
    
    
    /// Constructs a URL for QR Code from  a given `OathMechanism`
    /// - Parameter mechanism: `OathMechanism` to be converted to url
    /// - Parameter imageUrl: image urls
    /// - Returns: QR Code `URL` from the mechanism
    static func createUrl(mechanism: OathMechanism, imageUrl: String?) -> URL? {
        var components = URLComponents()
        components.scheme = URIType.otpauth.rawValue
        components.host = mechanism.type
        components.queryItems = [URLQueryItem(name: "secret", value: mechanism.secret),
                                 URLQueryItem(name: "digits", value: String(mechanism.digits)),
                                 URLQueryItem(name: "algorithm", value: mechanism.algorithm.rawValue)]
        if let image = imageUrl {
            components.queryItems?.append(URLQueryItem(name: "image", value: image.base64URLSafeEncoded()))
        }
        
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
    
    
    /// Static method to create an `Account` from `URL`. Doesn't store anything
    /// - Parameter url: `URL` of the QR Code
    /// - Returns: Newly Created `Account` with a mechanism of a type of hotp or totp. nil if can't create an account
    public static func createAccount(url: URL) -> Account? {
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
        let account = Account(issuer: parser.issuer, accountName: parser.label)
        account.imageUrl = parser.image
        
        if authType == .hotp {
            let mechanism = HOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, counter: parser.counter, digits: parser.digits)
            FRALog.v("HOTPMechanism (\(mechanism.identifier) is created")
            account.mechanisms.append(mechanism)
        } else {
            let mechanism = TOTPMechanism(issuer: parser.issuer, accountName: parser.label, secret: parser.secret, algorithm: parser.algorithm, period: parser.period, digits: parser.digits)
            FRALog.v("TOTPMechanism (\(mechanism.identifier) is created")
            account.mechanisms.append(mechanism)
        }
        return account
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
