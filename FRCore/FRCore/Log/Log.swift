//
//  Log.swift
//  FRCore
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 LogLevel is a representation of Log's type of log entry.\nAvailable LogLevels are:
     * none: no log entry is displayed on the debug console or log file
     * verbose: verbose level of log entry is displayed on the debug console or log file.
     * info: information level of log entry is displayed on the debug console or log file.
     * network: network level of log entry is displayed on the debug console or log file. All network traffics going in and out are through FRAuth SDK will be displayed with detailed information of request and response.
     * warning: warning level of log entry is displayed on the debug console or log file. Any minor issue, or error that would not impact the SDK's functionality will be displayed.
     * error: error level of log entry is displayed on the debug console or log file. Any severe issue, or major error that would impact the SDK's functionality will be displayed.
     * all: All types of log entry will be displayed on the debug console or log file.
 */
@objc(FRLogLevel)
public class LogLevel: NSObject, OptionSet {

    //  MARK: - Property
    
    /// rawValue of LogLevel
    public var rawValue: Int
    /// rawValue of LogLevel
    public typealias RawValue = Int
    /// none LogLevel indicates that there is no log
    @objc public static let none = LogLevel(rawValue: 1 << 0)
    /// verbose LogLevel indicates that the log entry is not important or can be ignored
    @objc public static let verbose = LogLevel(rawValue: 1 << 1)
    /// info LogLevel indicates that the log entry maybe helpful, or meaningful for debugging, or understanding the flow
    @objc public static let info = LogLevel(rawValue: 1 << 2)
    /// network LogLevel indicates the log entry of any network traffics, including request, and response
    @objc public static let network = LogLevel(rawValue: 1 << 3)
    /// warning LogLevel indicates the log entry of any minor issue or error that may occur which can be ignored
    @objc public static let warning = LogLevel(rawValue: 1 << 4)
    /// error LogLEvel indicates the log entry of any severe issue, or major error that impacts SDK's functionality or flow
    @objc public static let error = LogLevel(rawValue: 1 << 5)
    /// all LogLevel indicates the log entry of all LogLevels
    @objc public static let all = LogLevel(rawValue: 1 << 6)
    
    //  MARK: - Objective-C compatibility
    
    /// Init
    required public override convenience init() {
        self.init(rawValue: 0)
    }
    
    /// Initializes LogLevel with rawValue
    ///
    /// - Parameter rawValue: rawValue of LogLevel
    required public init(rawValue: Int) {
        self.rawValue = rawValue
        super.init()
    }
    
    
    /// Initializes LogLevel with set of LogLevels
    ///
    /// - Parameter logs: An array of LogLevel
    @objc
    @available(swift, obsoleted: 1.0)
    public convenience init(logs: [LogLevel]) {
        var logLevels: Int = 0
        for level in logs {
            logLevels = logLevels | level.rawValue
        }
        self.init(rawValue: logLevels)
    }
    
    
    /// Hash
    public override var hash: Int {
        return rawValue
    }
    
    
    /// Compares the LogLevel
    ///
    /// - Parameter object: Any object
    /// - Returns: Boolean result of whether object is equal to LogLevel or not
    public override func isEqual(_ object: Any?) -> Bool {
        guard let that = object as? LogLevel else {
            return false
        }
        return rawValue == that.rawValue
    }
    
    
    /// Concatenates with another LogLevel
    ///
    /// - Parameter other: Additional LogLevel to be concatenated
    public func formUnion(_ other: LogLevel) {
        rawValue = rawValue | other.rawValue
    }
    
    
    /// Makes intersection with another LogLevel
    ///
    /// - Parameter other: LogLevel
    public func formIntersection(_ other: LogLevel) {
        rawValue = rawValue & other.rawValue
    }
    
    
    /// Makes symmetric difference with another LogLevel
    ///
    /// - Parameter other: LogLevel
    public func formSymmetricDifference(_ other: LogLevel) {
        rawValue = rawValue ^ other.rawValue
    }
}


/**
 Log is a class responsible for Logging functionalities of FRCore SDK. Log can also be used in the application layer which then be displayed through FRCore SDK, and through OSLog with FRCore SDK's system label and LogLevel.
 
 ## Note ##
 By default, Log uses OSLog to display the log entry in the debug console, and in the log system of iOS; however, when *OS_ACTIVITY_MODE* is *disabled* in the environment variable, Log then uses default system *print()* method to display the log entry in the console only.
 */
@objc(FRDefulatLog)
public class Log: NSObject {
    
    //  MARK: - Property
    
    /// Current SDK version. We hard code it here as currently there is no other way to get it dinamically when used with SPM
    public static let sdkVersion = "4.6.0"
    /// Current LogLevel
    static var logLevel: LogLevel = .none
    /// Current Loggers to handle log entries
    static var loggers: [FRLogger] = [FRConsoleLogger()]
    /// Date formatter for log entries
    static var dateFormatter: DateFormatter?
    /// Defuault module name of Log
    static var DefaultModuleName: String {
        get {
            return "[FRCore]" + "[\(sdkVersion)]"
        }
    }
    
    
    //  MARK: - Method
    
    /// Enables log history for debugging purpose
    /// - Parameter enabled: Boolean value of whether or not to store all history of logs
    static func enableHistory(_ enabled: Bool) {
        for logger in loggers {
            if let frLogger = logger as? FRConsoleLogger {
                frLogger.enableHistory = enabled
            }
        }
    }
    
    /// Sets LogLevel
    ///
    /// - Parameter logLevel: Designated LogLevel to be displayed
    @objc
    public static func setLogLevel(_ logLevel: LogLevel) {
        Log.logLevel = logLevel
    }
    
    /// Sets Custom Logger
    ///
    /// - Parameter logger: Set logger will reset the logger to Custom Logger, Default Logger will be inactive
    @objc
    public static func setCustomLogger(_ logger: FRLogger) {
        self.loggers = [logger]
    }
    
    
    /// Generates date and time prefix with pre-defined dateFormatter
    ///
    /// - Returns: String value of current date and time
    static func generateTimePrefix() -> String {
        var timestamp = ""
        
        if let df = Log.dateFormatter {
            timestamp = df.string(from: Date())
        }
        else {
            let df = DateFormatter()
            df.dateFormat = "y-MM-dd H:m:ss.SSS"
            timestamp = df.string(from: Date())
        }
        
        return timestamp
    }
    
    
    /// Generates LogPrefix with filename, line number, and name of function that the entry was logged.
    ///
    /// - Parameters:
    ///   - file: String value of Filename
    ///   - line: Int value of Line# in the File
    ///   - function: String value of Function name
    /// - Returns: Combined, and formatted string value of all given information
    static func generateLogPrefix(file: String, line: Int, function: String) -> String {
        let fileComponents = file.split(separator: "/")
        
        if let callingFileName = fileComponents.last {
            return " [\(String(describing: callingFileName)):\(line) : \(function)]"
        }
        else {
            return " [\(function)]"
        }
    }
    
    
    //  MARK: - Log
    
    /// Prints verbose log level message
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - includeCallStack: Boolean indicator whether to include call stack or not
    ///   - module: String value of Module name
    ///   - file: Filename that the message was logged
    ///   - line: Line # in the File that the message was logged
    ///   - function: Name of method that the message was logged
    public static func v(_ message: String, _ includeCallStack: Bool? = true, module: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        guard Log.logLevel.contains(.verbose) || Log.logLevel.contains(.all), !Log.logLevel.contains(.none) else {
            return
        }
        let timePrefix = Log.generateTimePrefix()
        var logPrefix = (module ?? DefaultModuleName)
        if let includeCallStack = includeCallStack, includeCallStack {
            logPrefix += Log.generateLogPrefix(file: file, line: line, function: function)
        }
        
        for logger in Log.loggers {
            logger.logVerbose(timePrefix: timePrefix, logPrefix: logPrefix, message: message)
        }
    }
    
    
    /// Prints information log level message
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - includeCallStack: Boolean indicator whether to include call stack or not
    ///   - module: String value of Module name
    ///   - file: Filename that the message was logged
    ///   - line: Line # in the File that the message was logged
    ///   - function: Name of method that the message was logged
    public static func i(_ message: String, _ includeCallStack: Bool? = true, module: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        guard (Log.logLevel.contains(.info) || Log.logLevel.contains(.all)), !Log.logLevel.contains(.none) else {
            return
        }
        let timePrefix = Log.generateTimePrefix()
        var logPrefix = (module ?? DefaultModuleName)
        if let includeCallStack = includeCallStack, includeCallStack {
            logPrefix += Log.generateLogPrefix(file: file, line: line, function: function)
        }
        
        for logger in Log.loggers {
            logger.logInfo(timePrefix: timePrefix, logPrefix: logPrefix, message: message)
        }
    }
    
    
    /// Prints warning log level message
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - includeCallStack: Boolean indicator whether to include call stack or not
    ///   - module: String value of Module name
    ///   - file: Filename that the message was logged
    ///   - line: Line # in the File that the message was logged
    ///   - function: Name of method that the message was logged
    public static func w(_ message: String, _ includeCallStack: Bool? = true, module: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        guard Log.logLevel.contains(.warning) || Log.logLevel.contains(.all), !Log.logLevel.contains(.none) else {
            return
        }
        let timePrefix = Log.generateTimePrefix()
        var logPrefix = (module ?? DefaultModuleName)
        if let includeCallStack = includeCallStack, includeCallStack {
            logPrefix += Log.generateLogPrefix(file: file, line: line, function: function)
        }
        
        for logger in Log.loggers {
            logger.logWarning(timePrefix: timePrefix, logPrefix: logPrefix, message: message)
        }
    }
    
    
    /// Prints error log level message
    ///
    /// - Parameters:
    ///   - message: Log message
    ///   - includeCallStack: Boolean indicator whether to include call stack or not
    ///   - module: String value of Module name
    ///   - file: Filename that the message was logged
    ///   - line: Line # in the File that the message was logged
    ///   - function: Name of method that the message was logged
    public static func e(_ message: String, module: String? = nil, file: String = #file, line: Int = #line, function: String = #function) {
        guard Log.logLevel.contains(.error) || Log.logLevel.contains(.all), !Log.logLevel.contains(.none) else {
            return
        }
        let timePrefix = Log.generateTimePrefix()
        let logPrefix = (module ?? DefaultModuleName) + Log.generateLogPrefix(file: file, line: line, function: function)
        
        var callStack = "\n\tCall stack symbols:\n"
        for symbol in Thread.callStackSymbols {
            callStack += "\t\t\(symbol)\n"
        }
        
        for logger in Log.loggers {
            logger.logError(timePrefix: timePrefix, logPrefix: logPrefix, message: message + callStack)
        }
    }
    
    
    /// Prints detailed information of given reqeust
    ///
    /// - Parameters:
    ///   - request: Request object that contains the log
    ///   - file: Filename that the request was logged
    ///   - line: Filename that the request was logged
    ///   - function: Name of method that the request was logged
    static func logRequest(_ request: Request, file: String = #file, line: Int = #line, function: String = #function) {
        
        guard Log.logLevel.contains(.network) || Log.logLevel.contains(.all), !Log.logLevel.contains(.none) else {
            return
        }
        
        var log = "Request | [\(request.method.rawValue)] " + request.url
        log += "\n\tRequest Type: \(request.requestType.rawValue) | Response Type: \(request.responseType?.rawValue ?? "not set") | Timeout Interval: \(request.timeoutInterval)"
        
        if request.headers.keys.count > 0 {
            log += "\n\tAdditional Headers: \(request.headers)"
        }
        
        if request.urlParams.keys.count > 0 {
            log += "\n\tURL Parameters: \(request.urlParams)"
        }
        
        if request.bodyParams.keys.count > 0 {
            log += "\n\tBody Parameters: \(request.bodyParams)"
        }
        
        let timePrefix = Log.generateTimePrefix()
        
        for logger in Log.loggers {
            logger.logNetwork(timePrefix: timePrefix, logPrefix: DefaultModuleName, message: log)
        }
    }
    
    
    /// Prints detailed information of given response
    ///
    /// - Parameters:
    ///   - elapsed: Elapsed time that the response was received after the request is initiated
    ///   - data: Response data
    ///   - response: URLResponse object
    ///   - error: Error of the response
    static func logResponse(_ elapsed: Int, _ data: Data?, _ response: URLResponse?, _ error: Error?) {
        
        guard Log.logLevel.contains(.network) || Log.logLevel.contains(.all), !Log.logLevel.contains(.none) else {
            return
        }
        
        var log = "Response |"
        
        if let httpResponse = response as? HTTPURLResponse {
            
            var networkResult = ""
            if (200 ..< 303) ~= httpResponse.statusCode {
                networkResult = "✅"
            }
            else {
                networkResult = "🛑"
            }
            
            if let url = httpResponse.url {
                log += " [\(networkResult) \(httpResponse.statusCode)] : \(url.absoluteString) in \(elapsed) ms"
            }
            else {
                log += " [\(networkResult) \(httpResponse.statusCode)] in \(elapsed) ms"
            }
            
            log += "\n\tResponse Header: \(httpResponse.allHeaderFields)"
        }
        
        if let error = error as NSError? {
            log += " [🛑 Error]\n\tError: \(error.domain) | \(error.code) | \(error.localizedDescription) | \(error.userInfo)"
        }
        
        if let thisData = data {
            if let responseString = String(data: thisData, encoding: .utf8) {
                log += "\n\tResponse Data: \(responseString)"
            }
            else {
                log += "\n\tResponse Data: \(thisData)"
            }
        }
        
        let timePrefix = Log.generateTimePrefix()
        
        for logger in Log.loggers {
            logger.logNetwork(timePrefix: timePrefix, logPrefix: DefaultModuleName, message: log)
        }
    }
}
