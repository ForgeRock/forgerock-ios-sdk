//
//  FRLogger.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

protocol FRLogger {
    var queue: DispatchQueue { get }
    
    func logVerbose(timePrefix: String, logPrefix: String, message: String)
    func logInfo(timePrefix: String, logPrefix: String, message: String)
    func logNetwork(timePrefix: String, logPrefix: String, message: String)
    func logWarning(timePrefix: String, logPrefix: String, message: String)
    func logError(timePrefix: String, logPrefix: String, message: String)
}
