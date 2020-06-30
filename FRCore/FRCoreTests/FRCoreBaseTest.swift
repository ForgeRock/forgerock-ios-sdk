// 
//  FRCoreBaseTest.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore

class FRCoreBaseTest: XCTestCase {

    override func setUp() {
        Log.setLogLevel(.all)
        self.continueAfterFailure = false
    }

    override func tearDown() {
        
    }
}

extension URL {
    
    /// Extracts value in given URL's URL parameters
    ///
    /// - Parameter queryParamaterName: String value of parameter name in URL query parameter
    /// - Returns: String value of given parameter name
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}
