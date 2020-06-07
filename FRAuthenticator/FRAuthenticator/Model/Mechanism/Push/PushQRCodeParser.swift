// 
//  PushQRCodeParser.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/// PushQRCodeParser is responsible for parsing QR Code data (as in URL) to appropriate Push Mechanism information
struct PushQRCodeParser {
    
    //  MARK: - Properties
    
    /// Supported type
    let supportedTypes: [String] = ["push"]
    /// scheme of QR Code URL; must be either 'pushauth'
    var scheme: String
    /// type of auth; must be 'push'
    var type: String
    /// issuer of Push Auth
    var issuer: String
    /// label, accountName, or username of Push Auth
    var label: String
    /// shared secret of Push Auth
    var secret: String
    /// registration endpoint for Push Auth
    var registrationEndpoint: URL
    /// authentication endpoint for Push Auth
    var authenticationEndpoint: URL
    /// message identifier for Push Auth
    var messageId: String
    /// challenge for Push Auth
    var challenge: String
    /// load balancer value
    var loadBalancer: String?
    /// background color in hex
    var backgroundColor: String?
    /// image URL of logo
    var image: String?
    
    
    //  MARK: - Init
    
    /// Constructs and validates given QR Code data (URL) for Push Mechanism
    /// - Parameter url: QR Code's data as in URL
    init(url: URL) throws {
        guard let scheme = url.scheme, scheme == "pushauth" else {
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
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            throw MechanismError.invalidQRCode
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            if let strVal = item.value {
                params[item.name] = strVal
            }
        }
        
        guard let secret = params["s"],
        let registrationEndpoint = params["r"],
        let authenticationEndpoint = params["a"],
        let messageId = params["m"],
        let challenge = params["c"],
        let issuerBase64Encoded = params["issuer"],
        let issuer = issuerBase64Encoded.base64Decoded() else {
                throw MechanismError.missingInformation("s, r, a, m, c or issuer")
        }
        
        guard let regUrlData = registrationEndpoint.decodeURL(), let regUrlStr = String(data: regUrlData, encoding: .utf8), let regURL = URL(string: regUrlStr), let authUrlData = authenticationEndpoint.decodeURL(), let authUrlStr = String(data: authUrlData, encoding: .utf8), let authURL = URL(string: authUrlStr) else {
                throw MechanismError.invalidInformation("registration and/or authentication URL")
        }
        
        if let imgUrlEncoded = params["image"], let imgUrlDecodedData = imgUrlEncoded.decodeURL(), let imageUrlStr = String(data: imgUrlDecodedData, encoding: .utf8) {
            self.image = imageUrlStr
        }
        
        self.secret = secret
        self.registrationEndpoint = regURL
        self.authenticationEndpoint = authURL
        self.messageId = messageId
        self.challenge = challenge.urlSafeDecoding()
        self.issuer = issuer
        self.loadBalancer = params["l"]?.base64Decoded()
        self.backgroundColor = params["b"]
    }
}
