// 
//  FRBaseTestCase.swift
//  FRAuthTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest
@testable import FRCore

class FRBaseTestCase: XCTestCase {
    
    //  MARK: - Properties
    
    var config: Config = Config()
    var configFileName: String = ""
    var shouldCleanup: Bool = true
    
    static var useMockServer: Bool = true
    var shouldLoadMockResponses: Bool {
        get {
            return FRBaseTestCase.useMockServer
        }
        set {
            FRBaseTestCase.useMockServer = newValue
        }
    }
    
    static var internalRequestsHistory: [Request] = []
    static var internalRequestActions: [Action] = []
    var requestHistory: [Request] {
        get {
            return FRBaseTestCase.internalRequestsHistory
        }
    }
    var actionHistory: [Action] {
        get {
            return FRBaseTestCase.internalRequestActions
        }
    }

    
    //  MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        self.shouldLoadMockResponses = true
        //  Set TestLogger
        Log.loggers = [FRTestLogger()]
        //  Set Log level to none to ignore logs for set-up
        Log.setLogLevel(.none)
        //  Register internal request interceptors for request tracking purpose
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [InternalRequestInterceptor()])
        
        //  Configure mock responses using URLProtocol
        URLProtocol.registerClass(FRTestNetworkStubProtocol.self)
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRTestNetworkStubProtocol.self]
        RestClient.shared.setURLSessionConfiguration(config: config)

        //  Enable Log level to all for tests
        Log.setLogLevel(.all)
        
        //  Load Config object
        if self.configFileName.count > 0 {
            do {
                self.config = try Config(self.configFileName)
            }
            catch {
                XCTFail("Failed to load test configuration file: \(error)")
            }
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        FRTestNetworkStubProtocol.mockedResponses = []
        FRTestNetworkStubProtocol.requestIndex = 0
    
        if self.shouldCleanup {
            RequestInterceptorRegistry.shared.registerInterceptors(interceptors: nil, shouldOverride: true)
        }
        
        FRBaseTestCase.internalRequestsHistory.removeAll()
        FRBaseTestCase.internalRequestActions.removeAll()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        FRTestNetworkStubProtocol.mockedResponses = []
        FRTestNetworkStubProtocol.requestIndex = 0
        
        if self.shouldCleanup {
            RequestInterceptorRegistry.shared.registerInterceptors(interceptors: nil, shouldOverride: true)
        }
        
        FRBaseTestCase.internalRequestsHistory.removeAll()
        FRBaseTestCase.internalRequestActions.removeAll()
    }
    
    
    //  MARK: - Helper methods
    
    func parseStringToDictionary(_ str: String) -> [String: Any] {
        return FRTestUtils.parseStringToDictionary(str)
    }
    
    func loadMockResponses(_ responseFileNames: [String]) {
        FRTestUtils.loadMockResponses(responseFileNames)
    }
    
    func readDataFromJSON(_ fileName: String) -> [String: Any]? {
        return FRTestUtils.readDataFromJSON(fileName)
    }
    
    func readConfigFile(fileName: String) -> [String: Any] {
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            XCTFail("Failed to read \(fileName).plist file")
            return [:]
        }
        
        return config
    }
}

extension URL {
    
    /// Extracts value in given URL's URL parameters
    ///
    /// - Parameter queryParamaterName: String value of parameter name in URL query parameter
    /// - Returns: String value of given parameter name
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}

class InternalRequestInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        FRBaseTestCase.internalRequestsHistory.append(request)
        FRBaseTestCase.internalRequestActions.append(action)
        return request
    }
}
