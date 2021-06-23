//
//  Base64.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation

class Base64 {
    
    
    static func encodeBase64(_ bytes: [UInt8]) -> String {
        return encodeBase64(Data(bytes))
    }
    
    static func encodeBase64(_ data: Data) -> String {
        return data.base64EncodedString()
    }

    static func encodeBase64URL(_ bytes: [UInt8]) -> String {
        return encodeBase64URL(Data(bytes))
    }

    static func encodeBase64URL(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
