//
//  FRPinningHandler.swift
//  FRCore
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

@objc
public protocol FRPinningHandlerProtocol: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void)
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

/// This class implements URLSessionTaskDelegate protocol to handle HTTP redirect and SSL Pinning
open class FRPinningHandler: NSObject, FRPinningHandlerProtocol {
    
    private let frSecurityConfiguration: FRSecurityConfiguration
    
    public init(frSecurityConfiguration: FRSecurityConfiguration) {
        self.frSecurityConfiguration = frSecurityConfiguration
        super.init()
    }
    
    /// Handles HTTP redirection within NSURLSession
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - task: Current URLSessionTask
    ///   - response: Response of current task which may explain reason for redirection
    ///   - request: Newly constructed URLRequest object
    ///   - completionHandler: Completion callback
    open func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    
    /// URLSessionDelegate method for Authentication Challenge
    ///
    /// - Parameters:
    ///   - session: URLSession
    ///   - challenge: URLAuthenticationChallenge
    ///   - completionHandler: Completion callback
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        self.frSecurityConfiguration.validateSessionAuthChallenge(session: session, challenge: challenge, completionHandler: completionHandler)
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        self.frSecurityConfiguration.validateTaskAuthChallenge(session: session, task: task, challenge: challenge, completionHandler: completionHandler)
    }
}
