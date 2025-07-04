//
//  FRLogger.swift
//  FRCore
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

@objc
public protocol FRLogger {
    func logVerbose(timePrefix: String, logPrefix: String, message: String)
    func logInfo(timePrefix: String, logPrefix: String, message: String)
    func logNetwork(timePrefix: String, logPrefix: String, message: String)
    func logWarning(timePrefix: String, logPrefix: String, message: String)
    func logError(timePrefix: String, logPrefix: String, message: String)
}

@objc
public protocol FRHistory {
    var queue: DispatchQueue { get }
    var enableHistory: Bool { get set }
    var logHistory: [String] { get }
}
