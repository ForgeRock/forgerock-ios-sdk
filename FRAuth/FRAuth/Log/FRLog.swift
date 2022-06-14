// 
//  FRLog.swift
//  FRAuth
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/**
FRLog is a class responsible for Logging functionalities of FRAuth SDK. FRLog can also be used in the application layer which then be displayed through FRAuth SDK, and through OSLog with FRAuth SDK's system label and LogLevel.

## Note ##
By default, FRLog uses OSLog to display the log entry in the debug console, and in the log system of iOS; however, when *OS_ACTIVITY_MODE* is *disabled* in the environment variable, FRLog then uses default system *print()* method to display the log entry in the console only.
*/
@objc public class FRLog: NSObject {
    
    /// Module name of FRLog
    static var ModuleName: String {
        get {
            return "[FRAuth]" + "[\(FRCore.Log.sdkVersion)]"
        }
    }
    
    //  MARK: - Method
    
    /// Sets LogLevel
    ///
    /// - Parameter logLevel: Designated LogLevel to be displayed
    @objc public static func setLogLevel(_ logLevel: LogLevel) {
        Log.setLogLevel(logLevel)
    }
    
    //  MARK: - Method
    
    /// Sets CustomLogger
    ///
    /// - Parameter logger: Set logger will reset the logger to Custom Logger, Default Logger will be inactive
    @objc public static func setCustomLogger(_ logger: FRLogger) {
        Log.setCustomLogger(logger)
    }
    
    public static func v(_ message: String, subModule: String? = nil, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        var newMessage = message
        if let subModule = subModule {
            newMessage = subModule + " " + message
        }
        Log.v(newMessage, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    public static func i(_ message: String, subModule: String? = nil, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        var newMessage = message
        if let subModule = subModule {
            newMessage = subModule + " " + message
        }
        Log.i(newMessage, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    
    public static func w(_ message: String, subModule: String? = nil, _ includeCallStack: Bool? = true, file: String = #file, line: Int = #line, function: String = #function) {
        var newMessage = message
        if let subModule = subModule {
            newMessage = subModule + " " + message
        }
        Log.w(newMessage, includeCallStack, module: ModuleName, file: file, line: line, function: function)
    }
    
    public static func e(_ message: String, subModule: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        var newMessage = message
        if let subModule = subModule {
            newMessage = subModule + " " + message
        }
        Log.e(newMessage, module: ModuleName, file: file, line: line, function: function)
    }
}
