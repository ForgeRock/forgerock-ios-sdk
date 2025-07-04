// 
//  FRALog.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/**
FRALog is a class responsible for Logging functionalities of FRAuthenticator SDK. FRALog can also be used in the application layer which then be displayed through FRALog SDK, and through OSLog with FRALog SDK's system label and LogLevel.

## Note ##
By default, FRALog uses OSLog to display the log entry in the debug console, and in the log system of iOS; however, when *OS_ACTIVITY_MODE* is *disabled* in the environment variable, FRALog then uses default system *print()* method to display the log entry in the console only.
*/
public struct FRALog {
    
    /// Module name of FRLog
    static var ModuleName: String {
        get {
            return "[FRAuthenticator]" + "[\(FRCore.Log.sdkVersion)]"
        }
    }
    
    //  MARK: - Method
    
    /// Sets LogLevel
    ///
    /// - Parameter logLevel: Designated LogLevel to be displayed
    public static func setLogLevel(_ logLevel: LogLevel) {
        Log.setLogLevel(logLevel)
    }
    
    public static func v(_ message: String, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        Log.v(message, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    public static func i(_ message: String, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        Log.i(message, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    
    public static func w(_ message: String, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        Log.w(message, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    public static func e(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        Log.e(message, module: ModuleName, file: file, line: line, function: function)
    }
}
