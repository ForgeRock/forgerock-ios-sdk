// 
//  LogTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
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
        Log.enableHistory(true)
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
        
        Log.v("verbose")
        Log.i("info")
        Log.w("warning")
        Log.e("error")
        let request = Request(url: "test", method: .DELETE)
        Log.logRequest(request)
        Log.logResponse(10, nil, nil, nil)
        
        guard let logger = Log.loggers.first else {
            XCTFail("Failed to retrieve Logger")
            return
        }
        
        XCTAssertTrue(logger.enableHistory)
        XCTAssertEqual(logger.logHistory.count, 6)
    }
    
    
    func test_02_test_log_level_verbose_only() {
        
        Log.setLogLevel(.verbose)
        
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
}
