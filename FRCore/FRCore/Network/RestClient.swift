//
//  RestClient.swift
//  FRCore
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import UIKit

/// Completion callback for REST API result as `Result` instance
public typealias ResultCallback = (Result) -> Void

/// This class is responsible to handle REST API request, and acts as HTTP client for SDK Core
@objc
public class RestClient: NSObject {
    
    //  MARK: - Property
    
    /// Singleton instance for `RestClient`
    @objc public static let shared = RestClient()
    /// URLSession to be consumed through RestClient
    var _urlSession: URLSession?
    /// An array of RequestInterceptor
    var interceptors: [RequestInterceptor]?
    
    /// URLSession instance variable for `RestClient`
    fileprivate var session: URLSession {
        get {
            if let urlSession = _urlSession {
                return urlSession
            }
            else {
                let config = URLSessionConfiguration.default
                config.httpCookieStorage = nil
                config.httpCookieAcceptPolicy = .never
                config.httpShouldSetCookies = false
                let urlSession = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)
                _urlSession = urlSession
                Log.v("Default URLSession created")
                
                return urlSession
            }
        }
        set {
            Log.v("Custom URLSession set")
            _urlSession = newValue
        }
    }
    
    
    //  MARK: - Invoke
    
    /// Invokes REST API Request with `Request` object
    ///
    /// - Parameters:
    ///   - request: `Request` object for API request which should contain all information regarding the request
    ///   - action: Optional `Action` object that represents a type of Request
    ///   - completion: `Result` completion callback
    public func invoke(request: Request, action: Action? = nil, completion: @escaping ResultCallback) {
        
        //  Intercept request with current set of interceptors
        let thisRequest = self.interceptRequest(originalRequest: request, action: action)
        
        //  Validate whether `Request` object is valid; otherwise, return an error
        guard let urlRequest = thisRequest.build() else {
            completion(Response(data: nil, response: nil, error: NetworkError.invalidRequest(thisRequest.debugDescription)).parseReponse())
            return
        }
        
        // Log request / capture request start
        Log.logRequest(thisRequest)
        let start = DispatchTime.now()
        
        var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "com.forgerock.ios.frauth.restclient.backgroundTask", expirationHandler: {() -> Void in
            bgTask = UIBackgroundTaskIdentifier.invalid
            UIApplication.shared.endBackgroundTask(bgTask)
        })
        
        //  Invoke the request using URLSession, and handle the result with `Response` object
        self.session.dataTask(with: urlRequest) { (data, response, error) in
            // Log elapsed time / response
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Int(nanoTime) / 1_000_000
            Log.logResponse(timeInterval, data, response, error)
            
            // Complete the request
            completion(Response(data: data, response: response, error: error).parseReponse())
            UIApplication.shared.endBackgroundTask(bgTask)
        }.resume()
    }
    
    
    /// Invokes synchronously REST API Request with `Request` object
    ///
    /// - Parameter request: `Request` object for API request which should contain all information regarding the request
    /// - Parameter action: Optional `Action` object that represents a type of Request
    /// - Returns: `Result` instance of API Request
    public func invokeSync(request: Request, action: Action? = nil) -> Result {
        
        //  Intercept request with current set of interceptors
        let thisRequest = self.interceptRequest(originalRequest: request, action: action)
        
        //  Validate whether `Request` object is valid; otherwise, return an error
        guard let urlRequest = thisRequest.build() else {
            return Response(data: nil, response: nil, error: NetworkError.invalidRequest(thisRequest.debugDescription)).parseReponse()
        }
        
        // Log request / capture request start
        Log.logRequest(thisRequest)
        let start = DispatchTime.now()
        
        // Sync request
        let (data, response, error) = self.session.synchronousDataTask(urlrequest: urlRequest)
        
        // Log elapsed time / response
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
        let timeInterval = Int(nanoTime) / 1_000_000
        Log.logResponse(timeInterval, data, response, error)
        
        return Response(data: data, response: response, error: error).parseReponse()
    }
    
    
    /// Intercepts current Request object, and evaluates with given set of RequestInterceptors to update the original request
    /// - Parameter originalRequest: original Request object
    /// - Returns: updated Request object with given set of RequestInterceptors
    func interceptRequest(originalRequest: Request, action: Action? = nil) -> Request {
        if let action = action, let interceptors = self.interceptors {
            Log.i("Request found with Action (\(action.type); processing with RequestInterceptors (\(interceptors.count) found)")
            Log.i("Original Request: \(originalRequest.debugDescription)")
            var currentRequest = originalRequest
            for interceptor in interceptors {
                Log.i("Start processing: \(String(describing: interceptor))")
                currentRequest = interceptor.intercept(request: currentRequest, action: action)
                Log.i("Executed \(String(describing: interceptor)); updated Request: \(currentRequest.debugDescription)")
            }
            
            return currentRequest
        }
        Log.v("RequestInterceptor not found; proceeding with original request")
        
        return originalRequest
    }
    
    
    //  MARK: - Config
    
    /// Sets custom URLSessionConfiguration for RestClient's URLSession object
    ///
    /// - Parameter config: custom URLSessionConfiguration object
    @objc
    public func setURLSessionConfiguration(config: URLSessionConfiguration) {
        Log.v("Custom URLSessionConfiguration set \(config.debugDescription)")
        let session = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)
        self.session = session
    }
    
    
    //  MARK: - RequestInterceptors
    
    /// Registers an array of RequestInterceptors to intercept and modify Requests originated by SDK
    /// - Parameter interceptors: An array of RequestInterceptors
    func setRequestInterceptors(interceptors: [RequestInterceptor]?) {
        self.interceptors = interceptors
    }
}

extension URLSession {
    
    /// Performs asynchronous HTTP operation
    ///
    /// - Parameter urlrequest: URLRequest object to be performed
    /// - Returns: Result of HTTP operation in tuple
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2
            semaphore.signal()
        }
        dataTask.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}

/// This class implements URLSessionTaskDelegate protocol to handle HTTP redirect
class RedirectHandler:NSObject, URLSessionTaskDelegate {
    
    /// Handles HTTP redirection within NSURLSession
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: Current URLSessionTask
    ///   - response: Response of current task which may explain reason for redirection
    ///   - request: Newly constructed URLRequest object
    ///   - completionHandler: Completion callback
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        Log.i("HTTP Request re-directed: \n\tSession: \(session.debugDescription)\n\tTask: \(task.debugDescription)\n\tResponse: \(response.debugDescription)\n\tNew Request: \(request.debugDescription)")
        completionHandler(nil)
    }
}
