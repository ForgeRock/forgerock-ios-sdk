//
//  PingOneProtectInitializeCallback.swift
//  PingProtect
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
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
    /// The agentIdentification received from server
    public private(set) var agentIdentification: Bool = Bool()
    /// The agentTimeout received from server
    public private(set) var agentTimeout: Int?
    /// The agentPort received from server
    public private(set) var agentPort: String?
    
    
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
        
        // Optional - defaults to false if not provided by server
        if let consoleLogEnabled = self.outputValues[CBConstants.consoleLogEnabled] as? Bool {
            self.consoleLogEnabled = consoleLogEnabled
        } else {
            FRLog.i("Missing consoleLogEnabled - now optional")
            self.consoleLogEnabled = false
        }
        
        // Optional - defaults to empty array if not provided by server
        if let deviceAttributesToIgnore = self.outputValues[CBConstants.deviceAttributesToIgnore] as? [String] {
            self.deviceAttributesToIgnore = deviceAttributesToIgnore
        } else {
            FRLog.i("Missing deviceAttributesToIgnore - now optional")
            self.deviceAttributesToIgnore = []
        }
        
        // Optional - defaults to empty string if not provided by server
        if let customHost = self.outputValues[CBConstants.customHost] as? String {
            self.customHost = customHost
        } else {
            FRLog.i("Missing customHost - now optional")
            self.customHost = ""
        }
        
        // Optional - defaults to false if not provided by server
        if let lazyMetadata = self.outputValues[CBConstants.lazyMetadata] as? Bool {
            self.lazyMetadata = lazyMetadata
        } else {
            FRLog.i("Missing lazyMetadata - now optional")
            self.lazyMetadata = false
        }
        
        guard let behavioralDataCollection = self.outputValues[CBConstants.behavioralDataCollection] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing behavioralDataCollection")
        }
        self.behavioralDataCollection = behavioralDataCollection
        
        // Optional - defaults to false if not provided by server
        if let agentIdentification = self.outputValues[CBConstants.agentIdentification] as? Bool {
            self.agentIdentification = agentIdentification
        } else {
            FRLog.i("Missing agentIdentification - now optional")
            self.agentIdentification = false
        }
        
        // Optional - not included by default
        if let agentTimeout = self.outputValues[CBConstants.agentTimeout] as? Int {
            self.agentTimeout = agentTimeout
        } else {
            FRLog.i("Missing agentTimeout - now optional")
            self.agentTimeout = nil
        }
        
        // Optional - not included by default
        if let agentPort = self.outputValues[CBConstants.agentPort] as? String {
            self.agentPort = agentPort
        } else {
            FRLog.i("Missing agentPort - now optional")
            self.agentPort = nil
        }
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
                                      behavioralDataCollection: behavioralDataCollection,
                                      agentIdentification: agentIdentification,
                                      agentTimeout: agentTimeout,
                                      agentPort: agentPort)
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
