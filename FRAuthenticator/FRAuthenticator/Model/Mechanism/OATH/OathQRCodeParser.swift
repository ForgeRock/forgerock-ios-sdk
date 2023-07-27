// 
//  QRCodeParser.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// OauthQRCodeParser is responsible for parsing QR Code data (as in URL) to appropriate OATH information
struct OathQRCodeParser {
    
    //  MARK: - Properties
    
    /// Supported types
    let supportedTypes: [String] = [AuthType.totp.rawValue, AuthType.hotp.rawValue]
    /// scheme of QR Code URL; must be either 'otpauth' or 'pushauth'
    var scheme: String
    /// type of OATH; must be either 'totp' or 'hotp'
    var type: String
    /// issuer of OATH
    var issuer: String
    /// label, accountName, or username of OATH
    var label: String
    /// shared secret of OATH
    var secret: String
    /// defined algorithm of OATH
    var algorithm: String
    /// OATH algorithm enum
    var oathAlgorithm: OathAlgorithm
    /// number of digits for OTP
    var digits: Int?
    /// valid timeframe for OTP credentials
    var period: Int?
    /// number of time that OTP generated
    var counter: Int?
    /// HEX code value of background color in String
    var backgroundColor: String?
    /// image URL of logo
    var image: String?
    /// Set of policies
    var policies: String?
    
    //  MARK: - Init
    
    /// Constructs and validates given QR Code data (URL) for OATH
    /// - Parameter url: QR Code's data as in URL
    init(url: URL) throws {
        
        guard let scheme = url.scheme, (scheme == URIType.otpauth.rawValue || scheme == URIType.mfauth.rawValue) else {
            throw MechanismError.invalidQRCode
        }
        self.scheme = scheme
        
        guard let type = url.host, supportedTypes.contains(type.lowercased()) else {
            throw MechanismError.invalidType
        }
        self.type = type
        
        var path = url.path
        if let i = path.firstIndex(of: "/") {
            path.remove(at: i)
        }
        let accountInfo = path.components(separatedBy: ":")
        guard accountInfo.count >= 1 else {
            throw MechanismError.missingInformation("issuer, or account name")
        }
        
        if accountInfo.count == 1 {
            self.issuer = ""
            self.label = accountInfo[0]
        }
        else {
            self.issuer = accountInfo[0]
            self.label = accountInfo[1]
        }
        
        var secretValue: String?
        var algorithmValue: String?
        var digitsValue: Int?
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "algorithm" {
                    algorithmValue = item.value
                }
                if item.name == "secret", let strVal = item.value {
                    secretValue = strVal
                }
                if item.name == "digits", let strVal = item.value, let intVal = Int(strVal) {
                    digitsValue = intVal
                }
                if item.name == "period" {
                    if let strVal = item.value {
                        if let intVal = Int(strVal) {
                            if intVal <= 0 {
                                throw MechanismError.invalidInformation("refresh period was not a positive number")
                            }
                            self.period = intVal
                        } else {
                            throw MechanismError.invalidInformation("refresh period was not a number: \(strVal)")
                        }
                    } 
                }
                if item.name == "image", let imgUrl = item.value {
                    if let imgUrlDecodedData = imgUrl.decodeURL() {
                        let imageUrlStr = String(data: imgUrlDecodedData, encoding: .utf8)
                        self.image = imageUrlStr
                    } else {
                        self.image = imgUrl
                    }
                }
                if item.name == "counter", let strVal = item.value, let intVal = Int(strVal) {
                    self.counter = intVal
                }
                if item.name == "b" {
                    self.backgroundColor = item.value
                }
                if item.name == "issuer", let strVal = item.value {
                    if self.scheme == URIType.mfauth.rawValue, let decodedVal = strVal.base64Decoded() {
                        self.issuer = decodedVal
                    } else {
                        self.issuer = strVal
                    }
                }
                if item.name == "policies", let strVal = item.value {
                    self.policies = strVal.base64Decoded()
                }
            }
        }
        
        if let digits = digitsValue {
            if digits == 6 || digits == 8 {
                self.digits = digits
            }
            else {
                throw MechanismError.invalidInformation("digits (\(digits))")
            }
        }
        else {
            self.digits = 6
        }
        
        if let algorithmStr = algorithmValue {
            if let oathAlgorithm = OathAlgorithm(algorithm: algorithmStr) {
                self.algorithm = algorithmStr.lowercased()
                self.oathAlgorithm = oathAlgorithm
            }
            else {
                throw MechanismError.invalidInformation("algorithm (\(algorithmStr))")
            }
        }
        else {
            self.algorithm = "sha1"
            self.oathAlgorithm = OathAlgorithm(algorithm: "sha1")!
        }
        
        guard let secret = secretValue else {
            throw MechanismError.missingInformation("secret")
        }
        
        self.secret = secret
        guard let _ = Crypto.parseSecret(secret: secret) else {
            throw MechanismError.invalidInformation("secret")
        }
        
        if self.issuer.count == 0 {
            self.issuer = self.label
        }
        
        if self.issuer == "" && self.label == "" {
            throw MechanismError.missingInformation("no identity is associated with this MFA account. Missing account name and issuer.")
        } else if self.label == "" {
            self.label = "Untitled"
        }
    }
}
