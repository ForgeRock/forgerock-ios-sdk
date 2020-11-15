// 
//  FRURLUtil.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

extension URL {
    
    /// Compares given URL object with host, scheme, port, and optionally relativePath
    /// - Parameters:
    ///   - url: URL to be compared
    ///   - shouldCheckPath: Boolean indicator of whether or not to validate relativePath as well
    /// - Returns: Boolean result whether or not two URLs are the same
    public func isSame(_ url: URL, shouldCheckPath: Bool = true) -> Bool {
        if (self.host == url.host && self.scheme == url.scheme && self.port == url.port) {
            if shouldCheckPath {
                if self.relativePath == "/" && url.relativePath == "" || self.relativePath == "" && url.relativePath == "/" {
                    return true
                } else if self.relativePath != url.relativePath {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    
    /// Extracts value in given URL's URL parameters
    ///
    /// - Parameter queryParamaterName: String value of parameter name in URL query parameter
    /// - Returns: String value of given parameter name
    public func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}
