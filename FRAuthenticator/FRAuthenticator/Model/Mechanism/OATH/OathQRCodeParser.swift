// 
//  QRCodeParser.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// OauthQRCodeParser is responsible for parsing QR Code data (as in URL) to appropriate OATH information
struct OathQRCodeParser {
    
    //  MARK: - Properties
    
    /// Supported types
    let supportedTypes: [String] = ["totp", "hotp"]
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
    var algorithm: String?
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
    
    
    //  MARK: - Init
    
    /// Constructs and validates given QR Code data (URL) for OATH
    /// - Parameter url: QR Code's data as in URL
    init(url: URL) throws {
        
        guard let scheme = url.scheme, (scheme == "otpauth" || scheme == "pushauth") else {
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
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "algorithm" {
                    self.algorithm = item.value
                }
                if item.name == "secret", let strVal = item.value {
                    secretValue = strVal
                }
                if item.name == "digits", let strVal = item.value, let intVal = Int(strVal), (intVal == 6 || intVal == 8) {
                    self.digits = intVal
                }
                if item.name == "period" {
                    if let strVal = item.value, let intVal = Int(strVal) {
                        self.period = intVal
                    }
                }
                if item.name == "image", let imgUrlEncoded = item.value, let imgUrlDecodedData = imgUrlEncoded.decodeURL(), let imageUrlStr = String(data: imgUrlDecodedData, encoding: .utf8) {
                    self.image = imageUrlStr
                }
                if item.name == "counter", let strVal = item.value, let intVal = Int(strVal) {
                    self.counter = intVal
                }
                if item.name == "b" {
                    self.backgroundColor = item.value
                }
                if item.name == "issuer", let strVal = item.value, self.issuer.count == 0 {
                    self.issuer = strVal
                }
            }
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
    }
}
