// 
//  FRCoreRequestCaptureProtocol.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit

class FRCoreRequestCaptureProtocol: URLProtocol {
    struct TestConstants {
         static let FRTestURLProtocolHandled = "FRTestURLProtocolHandled"
     }
    
    static var requestHistory: [URLRequest] = []
    override open class func canInit(with request: URLRequest) -> Bool {
        if !FRCoreRequestCaptureProtocol.requestHistory.contains(request) {
            FRCoreRequestCaptureProtocol.requestHistory.append(request)
        }
        return false
    }
}
