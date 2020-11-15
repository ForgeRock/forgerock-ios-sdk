// 
//  RequestInterceptorTests.swift
//  FRCoreTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import XCTest

class RequestInterceptorTests: FRBaseTestCase {

    static var intercepted: [String] = []
    static var payload: [String: Any]?
    
    override func setUp() {
        URLProtocol.registerClass(FRCoreRequestCaptureProtocol.self)

        // Construct URLSession with FRURLProtocol
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRCoreRequestCaptureProtocol.self]
        RestClient.shared.setURLSessionConfiguration(config: config)
    }
    
    
    override func tearDown() {
        super.tearDown()
        FRCoreRequestCaptureProtocol.requestHistory = []
        RequestInterceptorTests.intercepted = []
        RequestInterceptorTests.payload = nil
    }
    
    
    func test_01_request_captured_and_processed_interceptor() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [StartAuthenticateInterceptor()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .START_AUTHENTICATE)) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertTrue(requestUrl.absoluteString.contains("testKey=testVal"))
    }
    
    
    func test_02_request_captured_and_should_not_process_interceptor_for_different_action() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [StartAuthenticateInterceptor()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .AUTHORIZE)) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal"))
    }
    
    
    func test_03_request_captured_and_should_process_interceptors_in_order() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyOne(), DummyTwo(), DummyThree(), DummyFour()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .AUTHORIZE)) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertTrue(requestUrl.absoluteString.contains("testKey=testVal4"))
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 4)
        let interceptorsInOrder: [String] = ["DummyOne", "DummyTwo", "DummyThree", "DummyFour"]
        
        for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
    }
    

    func test_04_request_captured_and_should_not_process_interceptor_for_different_action_sync() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [StartAuthenticateInterceptor()])
        let _ = RestClient.shared.invokeSync(request: request, action: Action(type: .AUTHORIZE))
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal"))
    }
    
    
    func test_05_request_captured_and_should_process_interceptors_in_order_sync() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyOne(), DummyTwo(), DummyThree(), DummyFour()])
        let _ = RestClient.shared.invokeSync(request: request, action: Action(type: .AUTHORIZE))
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertTrue(requestUrl.absoluteString.contains("testKey=testVal4"))
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 4)
        let interceptorsInOrder: [String] = ["DummyOne", "DummyTwo", "DummyThree", "DummyFour"]
        
        for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
    }
    
    
    func test_06_request_not_captured_when_no_action_defined() {
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DummyOne(), DummyTwo(), DummyThree(), DummyFour()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal1"))
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal2"))
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal3"))
        XCTAssertFalse(requestUrl.absoluteString.contains("testKey=testVal4"))
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 0)
    }
    
    
    func test_07_request_captured_and_invoke_different_url() {
        
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [DifferentURLInterceptor()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .AUTHENTICATE)) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertTrue(requestUrl.absoluteString.hasPrefix("http://openam.example.com:8081"))
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 1)
    }
    
    
    func test_08_request_captured_in_seuqence_and_get_updated_request() {
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [InterceptorSequenceOne(), InterceptorSequenceTwo(), InterceptorSequenceThree()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .AUTHENTICATE)) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let urlRequest = FRCoreRequestCaptureProtocol.requestHistory.last else {
            XCTFail("Failed to retrieve URLRequest from URLRequestProtocol")
            return
        }

        guard let requestUrl = urlRequest.url else {
            XCTFail("Failed to parse URL from URLRequest")
            return
        }
        
        XCTAssertTrue(requestUrl.absoluteString.contains("sequence=three"))
        XCTAssertEqual(RequestInterceptorTests.intercepted.count, 3)
        let interceptorsInOrder: [String] = ["InterceptorSequenceOne", "InterceptorSequenceTwo", "InterceptorSequenceThree"]
        for (index, intercepted) in RequestInterceptorTests.intercepted.enumerated() {
            XCTAssertEqual(interceptorsInOrder[index], intercepted)
        }
    }
    
    
    func test_09_action_with_payload() {
        let request = Request(url: "https://httpbin.org/anything", method: .GET)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [PayloadInterceptor()])
        let ex = self.expectation(description: "Request submit")
        RestClient.shared.invoke(request: request, action: Action(type: .AUTHENTICATE, payload: ["testKey":"testVal"])) { (result) in
            switch result {
            case .success(_, _):
                break
            case .failure(_):
                break
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 60, handler: nil)
        
        guard let payload = RequestInterceptorTests.payload else {
            XCTFail("Failed to retrieve Action.payload from interceptor")
            return
        }
        XCTAssertTrue(payload.keys.contains("testKey"))
        XCTAssertEqual(payload["testKey"] as? String, "testVal")
    }
}


class PayloadInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("PayloadInterceptor")
        RequestInterceptorTests.payload = action.payload
        return request
    }
}


class StartAuthenticateInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("StartAuthenticateInterceptor")
        if action.type == ActionType.START_AUTHENTICATE.rawValue {
            var urlParams = request.urlParams
            urlParams["testKey"] = "testVal"
            
            let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
            
            return newRequest
        }
        else {
            return request
        }
    }
}


class DifferentURLInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("DifferentURLInterceptor")
        
        let newRequest = Request(url: "http://openam.example.com:8081", method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: request.urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}

class DummyOne: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("DummyOne")
        var urlParams = request.urlParams
        urlParams["testKey"] = "testVal1"
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}

class DummyTwo: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("DummyTwo")
        var urlParams = request.urlParams
        urlParams["testKey"] = "testVal2"
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}

class DummyThree: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("DummyThree")
        var urlParams = request.urlParams
        urlParams["testKey"] = "testVal3"
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}

class DummyFour: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("DummyFour")
        var urlParams = request.urlParams
        urlParams["testKey"] = "testVal4"
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}


class InterceptorSequenceOne: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("InterceptorSequenceOne")
        var urlParams = request.urlParams
        urlParams["sequence"] = "one"
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}


class InterceptorSequenceTwo: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("InterceptorSequenceTwo")
        var urlParams = request.urlParams
        if request.urlParams["sequence"] == "one" {
            urlParams["sequence"] = "two"
        }
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}


class InterceptorSequenceThree: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        RequestInterceptorTests.intercepted.append("InterceptorSequenceThree")
        var urlParams = request.urlParams
        if request.urlParams["sequence"] == "two" {
            urlParams["sequence"] = "three"
        }
        let newRequest = Request(url: request.url, method: request.method, headers: request.headers, bodyParams: request.bodyParams, urlParams: urlParams, requestType: request.requestType, responseType: request.responseType, timeoutInterval: request.timeoutInterval)
        return newRequest
    }
}


