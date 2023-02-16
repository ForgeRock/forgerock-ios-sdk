// 
//  URLUtil.swift
//  FRAuthenticator
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

extension URL {
    
    /// Extracts host of URL, and parses host into AuthType
    /// - Returns: AuthType enum value; if unsupported type is found, AuthType.unknown is returned
    func getAuthType() -> AuthType {
        guard let host = self.host, let authType = AuthType(rawValue: host) else {
            return .unknown
        }
        
        return authType
    }
    
    /// Extracts scheme of URL, and parses host into URIType
    /// - Returns: URIType enum value; if unsupported type is found, URIType.unknown is returned
    func getURIType() -> URIType {
        guard let scheme = self.scheme, let type = URIType(rawValue: scheme) else {
            return .unknown
        }
        
        return type
    }
}
