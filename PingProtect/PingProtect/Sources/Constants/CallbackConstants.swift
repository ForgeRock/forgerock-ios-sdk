//
//  CallbackConstants.swift
//  PingProtect
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRAuth

/// CBConstants is mainly responsible to maintain all constant values related to Callback implementation
struct CBConstants {
    
    static let type: String = "type"
    static let input: String = "input"
    static let output: String = "output"
    static let name: String = "name"
    static let value: String = "value"

    static let envId: String = "envId"
    static let pauseBehavioralData: String = "pauseBehavioralData"
    static let consoleLogEnabled: String = "consoleLogEnabled"
    static let deviceAttributesToIgnore = "deviceAttributesToIgnore"
    static let customHost = "customHost"
    static let lazyMetadata = "lazyMetadata"
    static let behavioralDataCollection = "behavioralDataCollection"
    
    static let signals: String = "signals"
    static let clientError: String = "clientError"
    
    static let riskEvaluationSignals: String =  "pingone_risk_evaluation_signals"
}
