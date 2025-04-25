//
//  PingOneProtectInitializeCallback.swift
//  PingProtect
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRAuth
import Foundation

/**
 * Callback to initialize PingOne Protect SDK
 */
open class PingOneProtectInitializeCallback: ProtectCallback {
    
    /// The envId received from server
    public private(set) var envId: String = String()
    /// The consoleLogEnabled received from server
    public private(set) var consoleLogEnabled: Bool = Bool()
    /// The deviceAttributesToIgnore received from server
    public private(set) var deviceAttributesToIgnore: [String] = [String]()
    /// The customHost received from server
    public private(set) var customHost: String = String()
    /// The lazyMetadata received from server
    public private(set) var lazyMetadata: Bool = Bool()
    /// The behavioralDataCollection received from server
    public private(set) var behavioralDataCollection: Bool = Bool()
    
    
    /// Designated initialization method for PingOneProtectInitializeCallback
    ///
    /// - Parameter json: JSON object of PingOneProtectInitializeCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        try super.init(json: json)
        
        guard let envId = self.outputValues[CBConstants.envId] as? String else {
            throw AuthError.invalidCallbackResponse("Missing envId")
        }
        self.envId = envId
        
        guard let consoleLogEnabled = self.outputValues[CBConstants.consoleLogEnabled] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing consoleLogEnabled")
        }
        self.consoleLogEnabled = consoleLogEnabled
        
        guard let deviceAttributesToIgnore = self.outputValues[CBConstants.deviceAttributesToIgnore] as? [String] else {
            throw AuthError.invalidCallbackResponse("Missing deviceAttributesToIgnore")
        }
        self.deviceAttributesToIgnore = deviceAttributesToIgnore
        
        guard let customHost = self.outputValues[CBConstants.customHost] as? String else {
            throw AuthError.invalidCallbackResponse("Missing customHost")
        }
        self.customHost = customHost
        
        guard let lazyMetadata = self.outputValues[CBConstants.lazyMetadata] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing lazyMetadata")
        }
        self.lazyMetadata = lazyMetadata
        
        guard let behavioralDataCollection = self.outputValues[CBConstants.behavioralDataCollection] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing behavioralDataCollection")
        }
        self.behavioralDataCollection = behavioralDataCollection
    }
    
    
    /// Initialize Ping Protect SDK
    /// - Parameter completion: Completion block for initialization result
    open func start(completion: @escaping ProtectResultCallback) {
        // If PIProtect.initSDK has been called in the project already, the following call will have no effect
        let initParams = PIInitParams(envId: envId,
                                      deviceAttributesToIgnore: deviceAttributesToIgnore,
                                      consoleLogEnabled: consoleLogEnabled,
                                      customHost: customHost,
                                      lazyMetadata: lazyMetadata,
                                      behavioralDataCollection: behavioralDataCollection)
        PIProtect.start(initParams: initParams) { error in
            if let error = error as? NSError {
                self.setClientError(error.localizedDescription)
                completion(.failure(error))
            } else {
                completion(.success)
            }
        }
        
        // We always want to resume Behavioral Data collection if `behavioralDataCollection` is set to TRUE on the server node
        if behavioralDataCollection {
            PIProtect.resumeBehavioralData()
        } else {
            PIProtect.pauseBehavioralData()
        }
    }

}
