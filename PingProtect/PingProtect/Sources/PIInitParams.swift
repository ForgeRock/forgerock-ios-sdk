//
//  PIInitParams.swift
//  PingProtect
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingOneSignals

/// Parameters for starting PIProtect SDK
public struct PIInitParams {
    
    var envId: String? = nil
    var deviceAttributesToIgnore: [String]? = nil
    var consoleLogEnabled: Bool = false
    var customHost: String? = nil
    var lazyMetadata: Bool = false
    var behavioralDataCollection: Bool = true
    var agentIdentification: Bool = false
    var agentTimeout: Int? = nil
    var agentPort: String? = nil
    var enableTrust: Bool? = nil
    
    /// Memberwise Initializer
    public init(envId: String? = nil, deviceAttributesToIgnore: [String]? = nil, consoleLogEnabled: Bool = false, customHost: String? = nil, lazyMetadata: Bool = false, behavioralDataCollection: Bool = true, agentIdentification: Bool = false, agentTimeout: Int? = nil, agentPort: String? = nil, enableTrust: Bool? = nil) {
        self.envId = envId
        self.deviceAttributesToIgnore = deviceAttributesToIgnore
        self.consoleLogEnabled = consoleLogEnabled
        self.customHost = customHost
        self.lazyMetadata = lazyMetadata
        self.behavioralDataCollection = behavioralDataCollection
        self.agentIdentification = agentIdentification
        self.agentTimeout = agentTimeout
        self.agentPort = agentPort
        self.enableTrust = enableTrust
    }
    
    
    func getPOInitParams() -> POInitParams {
        let poInitParams = POInitParams()
        poInitParams.envId = envId
        poInitParams.consoleLogEnabled = consoleLogEnabled
        poInitParams.deviceAttributesToIgnore = deviceAttributesToIgnore // [String]
        poInitParams.customHost = customHost
        poInitParams.lazyMetadata = lazyMetadata
        poInitParams.behavioralDataCollection = behavioralDataCollection
        // TODO: Uncomment when PingOneSignals SDK supports these properties
//         poInitParams.agentIdentification = agentIdentification
//         poInitParams.agentTimeout = agentTimeout
//         poInitParams.agentPort = agentPort
//         poInitParams.enableTrust = enableTrust
        
        return poInitParams
    }
}
