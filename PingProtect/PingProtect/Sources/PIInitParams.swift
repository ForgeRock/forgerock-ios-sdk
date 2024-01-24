//
//  PIInitParams.swift
//  PingProtect
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingOneSignals

/// Parameters for starting PIProtect SDK
public struct PIInitParams {
    
    var envId: String?
    var deviceAttributesToIgnore: [String]?
    var consoleLogEnabled: Bool
    var customHost: String?
    var lazyMetadata: Bool
    var behavioralDataCollection: Bool
    
    func getPOInitParams() -> POInitParams {
        let poInitParams = POInitParams()
        poInitParams.envId = envId
        poInitParams.consoleLogEnabled = consoleLogEnabled
        poInitParams.deviceAttributesToIgnore = deviceAttributesToIgnore // [String]
        poInitParams.customHost = customHost
        poInitParams.lazyMetadata = lazyMetadata
        poInitParams.behavioralDataCollection = behavioralDataCollection
        
        return poInitParams
    }
}
