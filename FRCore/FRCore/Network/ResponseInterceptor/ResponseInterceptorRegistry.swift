//
//  ResponseInterceptorRegistry.swift
//  FRCore
//
//  WestJet Custom Implementation
//

import Foundation


/// ResponseInterceptorRegistry is responsible to maintain, and manage an array of `ResponseInterceptor` for FRCore's network layer
open class ResponseInterceptorRegistry {
    
    //  MARK: - Property
    
    /// Shared instance of `ResponseInterceptorRegistry`
    public static let shared = ResponseInterceptorRegistry()
    
    
    //  MARK: - Public
    
    /// Registers a new array of interceptor to FRCore's network layer; the new array can override the existing interceptors, or append on top of existing array
    /// - Parameters:
    ///   - interceptors: An array of ResponseInterceptor to be registered
    ///   - shouldOverride: Boolean indicator whether or not to override existing array
    public func registerInterceptors(interceptors: [ResponseInterceptor]?, shouldOverride: Bool = true) {
        if shouldOverride {
            RestClient.shared.setResponseInterceptors(interceptors: interceptors)
        } else {
            if let interceptors = interceptors {
                var newInterceptors = RestClient.shared.responseInterceptors ?? []
                for interceptor in interceptors {
                    newInterceptors.append(interceptor)
                }
                RestClient.shared.setResponseInterceptors(interceptors: newInterceptors)
            }
        }
    }
}
