// 
//  FRTestLogger.swift
//  FRAuthTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

class FRTestLogger: FRLogger {

    var queue: DispatchQueue
    var logHistory: [String] = []
    var enableHistory: Bool = false
    
    init() {
        self.queue = DispatchQueue(label: "com.forgerock.ios.frlogger.frconsolelogger-dispatch-queue")
    }
    
    func logVerbose(timePrefix: String, logPrefix: String, message: String) {
        self.log(timePrefix: timePrefix, log: logPrefix + " [Verbose] " + message, logLevel: .verbose)
    }
    
    func logInfo(timePrefix: String, logPrefix: String, message: String) {
        self.log(timePrefix: timePrefix, log: logPrefix + " [ℹ️ - Info] " + message, logLevel: .info)
    }
    
    func logNetwork(timePrefix: String, logPrefix: String, message: String) {
        self.log(timePrefix: timePrefix, log: logPrefix + " [🌐 - Network] " + message, logLevel: .network)
    }
    
    func logWarning(timePrefix: String, logPrefix: String, message: String) {
        self.log(timePrefix: timePrefix, log: logPrefix + " [⚠️ - Warning] " + message, logLevel: .warning)
    }
    
    func logError(timePrefix: String, logPrefix: String, message: String) {
        self.log(timePrefix: timePrefix, log: logPrefix + " [❌ - Error] " + message, logLevel: .error)
    }
    
    func log(timePrefix: String, log: String, logLevel: LogLevel) {
        
        if self.enableHistory {
            self.logHistory.append("\(timePrefix) \(log)")
        }
        
        print("\(timePrefix) \(log)")
    }
}
