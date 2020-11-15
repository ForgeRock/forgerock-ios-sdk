// 
//  RequestInterceptorFactoryTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class RequestInterceptorFactoryTests: FRBaseTestCase {

    override func setUp() {
        super.setUp()
        RestClient.shared.interceptors = nil
    }
    
    
    override func tearDown() {
        super.tearDown()
        RestClient.shared.interceptors = nil
    }
    
    
    func test_01_register_interceptors() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 1)
    }
    
    
    func test_02_register_multiple_interceptors() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor(), DummyInterceptorTwo()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 2)
    }
    
    
    func test_03_register_multiple_interceptors_override_true() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 1)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor(), DummyInterceptorTwo()], shouldOverride: true)
        XCTAssertEqual(RestClient.shared.interceptors?.count, 2)
    }
    
    
    func test_04_register_multiple_interceptors_override_false() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 1)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor(), DummyInterceptorTwo()], shouldOverride: false)
        XCTAssertEqual(RestClient.shared.interceptors?.count, 3)
    }
    
    
    func test_05_register_null_override_false() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor(), DummyInterceptorTwo()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 2)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: nil, shouldOverride: false)
        XCTAssertEqual(RestClient.shared.interceptors?.count, 2)
    }
    
    
    func test_06_register_null_override_true() {
        XCTAssertNil(RestClient.shared.interceptors)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyInterceptor(), DummyInterceptorTwo()])
        XCTAssertEqual(RestClient.shared.interceptors?.count, 2)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: nil, shouldOverride: true)
        XCTAssertNil(RestClient.shared.interceptors)
    }
}

class DummyInterceptor: RequestInterceptor {
    
    func intercept(request: Request, action: Action) -> Request {
        return request
    }
}

class DummyInterceptorTwo: RequestInterceptor {
    
    func intercept(request: Request, action: Action) -> Request {
        return request
    }
}
