//
//  PingOneProtectInitializeCallback.swift
//  PingProtect
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import FRAuth

/**
 * Callback to initialize PingOne Protect SDK
 */
open class PingOneProtectInitializeCallback: MultipleValuesCallback {
    
    /// The envId received from server
    public private(set) var envId: String
    /// The consoleLogEnabled received from server
    public private(set) var consoleLogEnabled: Bool
    /// The deviceAttributesToIgnore received from server
    public private(set) var deviceAttributesToIgnore: [String]
    /// The customHost received from server
    public private(set) var customHost: String
    /// The lazyMetadata received from server
    public private(set) var lazyMetadata: Bool
    /// The behavioralDataCollection received from server
    public private(set) var behavioralDataCollection: Bool
    
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
    
    /// Designated initialization method for PingOneProtectInitializeCallback
    ///
    /// - Parameter json: JSON object of PingOneProtectInitializeCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]], let inputs = json[CBConstants.input] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        // parse outputs
        var outputDictionary = [String: Any]()
        for output in outputs {
            guard let outputName = output[CBConstants.name] as? String, let outputValue = output[CBConstants.value] else {
                throw AuthError.invalidCallbackResponse("Failed to parse output")
            }
            outputDictionary[outputName] = outputValue
        }
        
        guard let envId = outputDictionary[CBConstants.envId] as? String else {
            throw AuthError.invalidCallbackResponse("Missing envId")
        }
        self.envId = envId
        
        guard let consoleLogEnabled = outputDictionary[CBConstants.consoleLogEnabled] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing consoleLogEnabled")
        }
        self.consoleLogEnabled = consoleLogEnabled
        
        guard let deviceAttributesToIgnore = outputDictionary[CBConstants.deviceAttributesToIgnore] as? [String] else {
            throw AuthError.invalidCallbackResponse("Missing deviceAttributesToIgnore")
        }
        self.deviceAttributesToIgnore = deviceAttributesToIgnore
        
        guard let customHost = outputDictionary[CBConstants.customHost] as? String else {
            throw AuthError.invalidCallbackResponse("Missing customHost")
        }
        self.customHost = customHost
        
        guard let lazyMetadata = outputDictionary[CBConstants.lazyMetadata] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing lazyMetadata")
        }
        self.lazyMetadata = lazyMetadata
        
        guard let behavioralDataCollection = outputDictionary[CBConstants.behavioralDataCollection] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing behavioralDataCollection")
        }
        self.behavioralDataCollection = behavioralDataCollection
        
        //parse inputs
        var inputNames = [String]()
        for input in inputs {
            guard let inputName = input[CBConstants.name] as? String else {
                throw AuthError.invalidCallbackResponse("Failed to parse input")
            }
            inputNames.append(inputName)
        }
        
        guard let clientErrorKey = inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        try super.init(json: json)
        type = callbackType
        response = json
    }
    
    
    /// Initialize Ping Protect SDK
    /// - Parameter completion: Completion block for initialization result
    open func initialize(completion: @escaping ProtectResultCallback) {
        // If PIProtect.initSDK has been called in the project already, the following call will have no effect
        let initParams = PIInitParams(envId: envId,
                                      deviceAttributesToIgnore: deviceAttributesToIgnore,
                                      consoleLogEnabled: consoleLogEnabled,
                                      customHost: customHost,
                                      lazyMetadata: lazyMetadata,
                                      behavioralDataCollection: behavioralDataCollection)
        PIProtect.initSDK(initParams: initParams) { error in
            if let error = error {
                completion(.failure)
                self.setClientError("Protect SDK Initialization failed")
            } else {
                completion(.success)
            }
        }
        
        // We always want to resume Behavioral Data collection if `behavioralDataCollection` is set to TRUE on the server node
        if behavioralDataCollection {
            PIProtect.resumeBehavioralData()
        }
    }
    
    /// Sets `clientError` value in callback response
    /// - Parameter clientError: String value of `clientError`]
    public func setClientError(_ clientError: String) {
        self.inputValues[self.clientErrorKey] = clientError
    }
}
