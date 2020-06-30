//
//  FRConsoleLogger.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import os

class FRConsoleLogger: FRLogger {

    var queue: DispatchQueue
    var osLog: OSLog
    var osActivieModeEnabled: Bool = true
    var logHistory: [String] = []
    var enableHistory: Bool = false
    
    init() {
        self.queue = DispatchQueue(label: "com.forgerock.ios.frlogger.frconsolelogger-dispatch-queue")
        self.osLog = OSLog(subsystem: "com.forgerock.ios", category: "Default")
        
        if let osActivityMode = ProcessInfo.processInfo.environment["OS_ACTIVITY_MODE"], osActivityMode.lowercased() == "disable" {
            self.osActivieModeEnabled = false
        }
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
        
        let osLogType = self.converOSLogType(logLevel: logLevel)
        self.queue.async {
            if self.osActivieModeEnabled {
                os_log("%@", log: self.osLog, type: osLogType, log)
            }
            else {
                print("\(timePrefix) \(log)")
            }
        }
    }
    
    func converOSLogType(logLevel: LogLevel) -> OSLogType {
        var logType: OSLogType
        switch logLevel {
        case .info:
            logType = .info
            break
        case .network:
            logType = .debug
            break
        case .warning:
            logType = .error
            break
        case .error:
            logType = .fault
            break
        default:
            logType = .default
            break
        }
        
        return logType
    }
}
