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
    ///   - completion: `Result` completion callback
    public func invoke(request: Request, completion: @escaping ResultCallback) {
        
        //  Validate whether `Request` object is valid; otherwise, return an error
        guard let urlRequest = request.build() else {
            completion(Response(data: nil, response: nil, error: NetworkError.invalidRequest(request.debugDescription)).parseReponse())
            return
        }
        
        // Log request / capture request start
        Log.logRequest(request)
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
    /// - Returns: `Result` instance of API Request
    public func invokeSync(request: Request) -> Result {
        //  Validate whether `Request` object is valid; otherwise, return an error
        guard let urlRequest = request.build() else {
            return Response(data: nil, response: nil, error: NetworkError.invalidRequest(request.debugDescription)).parseReponse()
        }
        
        // Log request / capture request start
        Log.logRequest(request)
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
