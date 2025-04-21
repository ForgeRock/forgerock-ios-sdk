// 
//  LogTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class LogTests: FRBaseTestCase {

    override func setUp() {
        super.setUp()
        //  Construct Console Logger
        let logger = FRConsoleLogger()
        //  Change Queue, and OS Activity flag for automated tests
        logger.queue = DispatchQueue.main
        logger.osActivieModeEnabled = true
        //  Add logger to log system, and enable history
        Log.loggers = [logger]
    }
    
    
    override func tearDown() {
        //  Clear log history
        if let logger = Log.loggers.first as? FRConsoleLogger {
            logger.logHistory = []
        }
        super.tearDown()
    }

    
    func test_01_set_log_level_all() {
        
        Log.setLogLevel(.all)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRHistory else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 6)
    }
    
    
    func test_02_test_log_level_verbose_only() {
        
        Log.setLogLevel(.verbose)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 1)
        
        if let log = logger.logHistory.first {
            XCTAssertTrue(log.contains("Verbose"))
        }
    }
    
    
    func test_03_test_log_level_info_only() {
        
        Log.setLogLevel(.info)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 1)
        
        if let log = logger.logHistory.first {
            XCTAssertTrue(log.contains("Info"))
        }
    }
    
    
    func test_04_test_log_level_warning_only() {
        
        Log.setLogLevel(.warning)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 1)
        
        if let log = logger.logHistory.first {
            XCTAssertTrue(log.contains("Warning"))
        }
    }
    
    
    func test_05_test_log_level_error_only() {
        
        Log.setLogLevel(.error)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 1)
        
        if let log = logger.logHistory.first {
            XCTAssertTrue(log.contains("Error"))
        }
    }
    
    
    func test_06_test_log_level_network_only() {
        
        Log.setLogLevel(.network)
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 2)
        
        if let log = logger.logHistory.first {
            XCTAssertTrue(log.contains("Network"))
        }
    }
    
    
    func test_07_test_log_level_info_warning() {
        
        Log.setLogLevel([.info, .warning])
        Log.enableHistory(true)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first as? FRConsoleLogger else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 2)
        
        for log in logger.logHistory {
            if log.contains("Info") || log.contains("Warning") {
                
            }
            else {
                XCTFail("Failed to validate log message; unexpected log message found")
            }
        }
    }
    
    func test_custom_logger() {
        
        let customLogger = FRLoggerMock()
        Log.setCustomLogger(customLogger)
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        XCTAssertTrue(customLogger.logVerboseCallCount ==  1)
        XCTAssertTrue(customLogger.logInfoCallCount ==  1)
        XCTAssertTrue(customLogger.logWarningCallCount ==  1)
        XCTAssertTrue(customLogger.logErrorCallCount ==  1)
        XCTAssertTrue(customLogger.logNetworkCallCount ==  2)
        
    }
    
    
    func test_log_level() {
        Log.setLogLevel(.info)
        XCTAssertTrue(Log.logLevel == .info)
        Log.setLogLevel(.all)
        XCTAssertTrue(Log.logLevel == .all)
        Log.setLogLevel(.network)
        XCTAssertTrue(Log.logLevel == .network)
        Log.setLogLevel(.verbose)
        XCTAssertTrue(Log.logLevel == .verbose)
        Log.setLogLevel(.error)
        XCTAssertTrue(Log.logLevel == .error)
        Log.setLogLevel(.none)
        XCTAssertTrue(Log.logLevel == .none)
        XCTAssertTrue(Log.loggers.count > 0)
    }
    
    func test_default_logger() {
        let customLogger = FRLoggerMock()
        Log.loggers = [customLogger]
        Log.logLevel = .info
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        XCTAssertTrue(customLogger.logVerboseCallCount ==  0)
        XCTAssertTrue(customLogger.logInfoCallCount ==  1)
        XCTAssertTrue(customLogger.logWarningCallCount ==  0)
        XCTAssertTrue(customLogger.logErrorCallCount ==  0)
        XCTAssertTrue(customLogger.logNetworkCallCount ==  0)
    }
    
    func test_default_logger_with_all_enabled() {
        let customLogger = FRLoggerMock()
        Log.loggers = [customLogger]
        Log.logLevel = .all
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        XCTAssertTrue(customLogger.logVerboseCallCount ==  1)
        XCTAssertTrue(customLogger.logInfoCallCount ==  1)
        XCTAssertTrue(customLogger.logWarningCallCount ==  1)
        XCTAssertTrue(customLogger.logErrorCallCount ==  1)
        XCTAssertTrue(customLogger.logNetworkCallCount ==  2)
    }
    
}

public class FRLoggerMock: FRLogger {
    public init() { }

    public private(set) var logVerboseCallCount = 0
    public var logVerboseHandler: ((String, String, String) -> ())?
    public func logVerbose(timePrefix: String, logPrefix: String, message: String)  {
        logVerboseCallCount += 1
        if let logVerboseHandler = logVerboseHandler {
            logVerboseHandler(timePrefix, logPrefix, message)
        }
        
    }

    public private(set) var logInfoCallCount = 0
    public var logInfoHandler: ((String, String, String) -> ())?
    public func logInfo(timePrefix: String, logPrefix: String, message: String)  {
        logInfoCallCount += 1
        if let logInfoHandler = logInfoHandler {
            logInfoHandler(timePrefix, logPrefix, message)
        }
        
    }

    public private(set) var logNetworkCallCount = 0
    public var logNetworkHandler: ((String, String, String) -> ())?
    public func logNetwork(timePrefix: String, logPrefix: String, message: String)  {
        logNetworkCallCount += 1
        if let logNetworkHandler = logNetworkHandler {
            logNetworkHandler(timePrefix, logPrefix, message)
        }
        
    }

    public private(set) var logWarningCallCount = 0
    public var logWarningHandler: ((String, String, String) -> ())?
    public func logWarning(timePrefix: String, logPrefix: String, message: String)  {
        logWarningCallCount += 1
        if let logWarningHandler = logWarningHandler {
            logWarningHandler(timePrefix, logPrefix, message)
        }
        
    }

    public private(set) var logErrorCallCount = 0
    public var logErrorHandler: ((String, String, String) -> ())?
    public func logError(timePrefix: String, logPrefix: String, message: String)  {
        logErrorCallCount += 1
        if let logErrorHandler = logErrorHandler {
            logErrorHandler(timePrefix, logPrefix, message)
        }
        
    }
}
