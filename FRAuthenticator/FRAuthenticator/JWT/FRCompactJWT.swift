// 
//  FRCompactJWT.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// JWTType represents an enumeration of supported JWT type for FRCompactJWT object; currently, **FRAuthenticator SDK only supports HS256**
enum JWTType: String {
    case hs256 = "HS256"
    func generateHeader() -> [String: String] {
        var header: [String: String] = ["typ": "JWT"]
        switch self {
        case .hs256:
            header["alg"] = "HS256"
        }
        return header
    }
}


/// FRCompactJWT class is responsible to perform simple, and specific JWT operation within FRAuthenticator SDK
///
/// **Note**: FRCompactJWT is designed and intended to be used for very specific operation of FRAuthenticator SDK, and is not designed to be complete solution for JWT operations. FRCompactJWT class will only be responsible to perform JWT signing with HS256.
struct FRCompactJWT {
    
    /// Header  dictionary
    var header: [String: String]
    /// Payload dictionary
    var payload: [String: CodableValue]
    /// Secret string
    var secret: String
    
    
    /// Constructs FRCompactJWT object with given JWTType, secret string, and payload dictionary
    /// - Parameters:
    ///   - algorithm: JWTType that represents hash algorithm to be used for JWT
    ///   - secret: Secret as in string
    ///   - payload: JWT payload
    init(algorithm: JWTType, secret: String, payload: [String: CodableValue]) {
        
        self.header = algorithm.generateHeader()
        self.payload = payload
        self.secret = secret
    }
    
    
    /// Signs given FRCompactJWT object with given algorithm using HMAC
    /// - Throws: CryptoError,
    /// - Returns: Signed JWT string
    func sign() throws -> String {
    
        let encodedHeader = try FRJSONEncoder.shared.encodeToString(value: header)
        let encodedPayload = try FRJSONEncoder.shared.encodeToString(value: payload)
        
        let hmac = try Crypto.hmac(algorithm: .sha256, secret: secret, message: encodedHeader + "." + encodedPayload)
        let signature = hmac.urlSafeEncoding()
        
        return encodedHeader + "." + encodedPayload + "." + signature
    }
    
    
    
    /// Verifies the signature of given JWT and shared secret
    /// - Parameters:
    ///   - jwt: JWT as in string
    ///   - secret: Shared secret as in String
    /// - Throws: CryptoError
    /// - Returns: Boolean result whether or not if given JWT's signature is valid or not based on the given secret
    static func verify(jwt: String, secret: String) throws -> Bool {
        
        let components = jwt.split(separator: ".")
        guard components.count == 3 else {
            FRALog.e("Failed to parse JWT; given JWT does not have 3 components. \(jwt)")
            throw CryptoError.invalidJWT
        }
        
        let signatureStr = String(components[2])
        let payloadStr = String(components[1])
        var headerStr = String(components[0])
        headerStr = headerStr.base64Pad()
        
        guard let headerData = Data(base64Encoded: headerStr),
        let header = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: String] else {
            FRALog.e("Failed to conver JWT header data into dictionary")
            throw CryptoError.failToConvertData
        }
        
        guard let alg = header["alg"], let _ = JWTType(rawValue: alg) else {
            FRALog.e("Given JWT type (\(header["alg"] ?? "")) is not supported.")
            throw CryptoError.unsupportedJWTType
        }
        
        let rawString = headerStr + "." + payloadStr
        let urlUnsafeSignature = try Crypto.hmac(algorithm: .sha256, secret: secret, message: rawString)
        
        return urlUnsafeSignature == signatureStr || urlUnsafeSignature.urlSafeEncoding() == signatureStr
    }
    
    
    /// Extracts JWT payload data, and parses/decodes into dictionary
    /// - Parameter jwt: JWT as String
    /// - Throws: CryptoError
    /// - Returns: Dictionary containing JWT payload
    static func extractPayload(jwt: String) throws -> [String: Any] {
        
        let components = jwt.split(separator: ".")
        guard components.count == 3 else {
            FRALog.e("Failed to parse JWT; given JWT does not have 3 components. \(jwt)")
            throw CryptoError.invalidJWT
        }
        var payloadStr = String(components[1])
        payloadStr = payloadStr.urlSafeDecoding().base64Pad()
        
        guard let payloadData = Data(base64Encoded: payloadStr),
        let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            FRALog.e("Failed to conver JWT payload data into dictionary")
            throw CryptoError.failToConvertData
        }
        
        return payload
    }
}
