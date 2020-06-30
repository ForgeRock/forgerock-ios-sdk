//
//  FRATestNetworkStubProtocol.swift
//  FRAuthenticatorTests
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

@objc
class FRATestNetworkStubProtocol: URLProtocol {
//    static mockedResponses: [FRTest]
    
    struct TestConstants {
        static let FRATestURLProtocolHandled = "FRATestURLProtocolHandled"
    }
    
    static var requestHistory: [URLRequest] = []
    static var mockedResponses: [FRATestStubResponseParser] = []
    static var requestIndex: Int = 0
    
    var session: URLSession?
    var sessionTask: URLSessionDataTask?
    var responseData: Data?
    var currentResponseParser: FRATestStubResponseParser?
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
    }
    
    public override class func canInit(with request: URLRequest) -> Bool {
        if FRATestNetworkStubProtocol.property(forKey: TestConstants.FRATestURLProtocolHandled, in: request) != nil {
            return false
        }
        print("[FRAuthTest] Proceeding protocol")
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        print("[FRAuthTest] session started with index \(FRATestNetworkStubProtocol.requestIndex)")
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        FRATestNetworkStubProtocol.requestHistory.append(request)
        
        FRATestNetworkStubProtocol.setProperty(true, forKey: TestConstants.FRATestURLProtocolHandled, in: mutableRequest)
        
        if FRATestNetworkStubProtocol.mockedResponses.count > FRATestNetworkStubProtocol.requestIndex {
            self.currentResponseParser = FRATestNetworkStubProtocol.mockedResponses[FRATestNetworkStubProtocol.requestIndex]
            FRATestNetworkStubProtocol.requestIndex += 1
            
            if let _ = self.currentResponseParser?.redirectRequest, let _ = self.currentResponseParser?.response {
                let task = session?.dataTask(with: mutableRequest as URLRequest)
                task?.resume()
            }
            else {
                
                if let response = self.currentResponseParser?.response {
                    let policy = URLCache.StoragePolicy(rawValue: mutableRequest.cachePolicy.rawValue) ?? .notAllowed
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
                }
                if let responseData = self.currentResponseParser?.responsePayload {
                    client?.urlProtocol(self, didLoad: responseData)
                }
                if let error = self.currentResponseParser?.error {
                    client?.urlProtocol(self, didFailWithError: error)
                }
                
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        else {
            client?.urlProtocol(self, didFailWithError: NetworkError.invalidRequest("Mock response was not found"))
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    public override func stopLoading() {
        print("[FRAuthTest] session stopped")
        sessionTask?.cancel()
    }
}

// Only handle URLSessionDataDelegate for redirect
extension FRATestNetworkStubProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: self.currentResponseParser!.response!, cacheStoragePolicy: policy)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Ignore the error on redirected request for server not reachable, and return the response instead
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: self.currentResponseParser!.response!, cacheStoragePolicy: policy)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: self.currentResponseParser!.redirectRequest!, redirectResponse: self.currentResponseParser!.response!)
        completionHandler(self.currentResponseParser!.redirectRequest!)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
}
