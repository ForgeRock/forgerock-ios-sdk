// 
//  DeviceSigningVerifierCallback.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import JOSESwift

/**
 * Callback to collect the device binding information
 */
open class DeviceSigningVerifierCallback: MultipleValuesCallback, Binding {
    
    //  MARK: - Properties
    
    /// The userId received from server
    public private(set) var userId: String?
    /// The challenge received from server
    public private(set) var challenge: String
    // The title to be displayed in biometric prompt
    public private(set) var title: String
    // The subtitle to be displayed in biometric prompt
    public private(set) var subtitle: String
    // The description to be displayed in biometric prompt
    public private(set) var promptDescription: String
    // The timeout to be to expire the biometric authentication
    public private(set) var timeout: Int?
    
    /// Jws input key in callback response
    private var jwsKey: String
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
    //  MARK: - Init
    
    /// Designated initialization method for DeviceSigningVerifierCallback
    ///
    /// - Parameter json: JSON object of DeviceSigningVerifierCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required public init(json: [String : Any]) throws {
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
        
        self.userId = outputDictionary[CBConstants.userId] as? String
        
        guard let challenge = outputDictionary[CBConstants.challenge] as? String else {
            throw AuthError.invalidCallbackResponse("Missing challenge")
        }
        self.challenge = challenge
        
        guard let title = outputDictionary[CBConstants.title] as? String else {
            throw AuthError.invalidCallbackResponse("Missing title")
        }
        self.title = title
        
        guard let subtitle = outputDictionary[CBConstants.subtitle] as? String else {
            throw AuthError.invalidCallbackResponse("Missing subtitle")
        }
        self.subtitle = subtitle
        
        guard let promptDescription = outputDictionary[CBConstants.description] as? String else {
            throw AuthError.invalidCallbackResponse("Missing description")
        }
        self.promptDescription = promptDescription
        
        self.timeout = outputDictionary[CBConstants.timeout] as? Int
        
        //parse inputs
        var inputNames = [String]()
        for input in inputs {
            guard let inputName = input[CBConstants.name] as? String else {
                throw AuthError.invalidCallbackResponse("Failed to parse input")
            }
            inputNames.append(inputName)
        }
        
        guard let jwsKey = inputNames.filter({ $0.contains(CBConstants.jws) }).first else {
            throw AuthError.invalidCallbackResponse("Missing jwsKey")
        }
        self.jwsKey = jwsKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        try super.init(json: json)
        type = callbackType
        response = json
    }
    
    
    /// Sign the challenge with binded device key
    /// - Parameter userKeySelector: ``UserKeySelector`` implementation - default value is `DefaultUserKeySelector()`
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` -default value is `deviceAuthenticatorIdentifier`
    /// - Parameter completion: Completion block for Device binding result callback
    open func sign(userKeySelector: UserKeySelector = DefaultUserKeySelector(),
                   deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                   completion: @escaping DeviceSigningResultCallback) {
        
        let deviceAuthenticator = deviceAuthenticator ?? deviceAuthenticatorIdentifier
        let dispatchQueue = DispatchQueue(label: "com.forgerock.concurrentQueue", qos: .userInitiated)
        dispatchQueue.async {
            self.execute(userKeySelector: userKeySelector, deviceAuthenticator: deviceAuthenticator, completion)
        }
    }
    
    
    /// Helper method to execute signing, show biometric prompt.
    /// - Parameter userKeyService: service to sort and fetch the keys stored in the device - default value is `UserDeviceKeyService()`
    /// - Parameter userKeySelector: ``UserKeySelector`` implementation - default value is  `DefaultUserKeySelector()`
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` - default value is `deviceAuthenticatorIdentifier`
    /// - Parameter completion: Completion block for Device signing result callback
    internal func execute(userKeyService: UserKeyService = UserDeviceKeyService(),
                          userKeySelector: UserKeySelector = DefaultUserKeySelector(),
                          deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                          _ completion: @escaping DeviceSigningResultCallback) {
        
        let deviceAuthenticator = deviceAuthenticator ?? deviceAuthenticatorIdentifier
        let status = userKeyService.getKeyStatus(userId: userId)
        
        switch status {
        case .singleKeyFound(key: let key):
            authenticate(userKey: key, authInterface: deviceAuthenticator(key.authType), completion)
        case .multipleKeysFound(keys: _):
            userKeySelector.selectUserKey(userKeys: userKeyService.userKeys) { key in
                if let key = key {
                    self.authenticate(userKey: key, authInterface: deviceAuthenticator(key.authType), completion)
                } else {
                    self.handleException(status: .abort, completion: completion)
                }
            }
            break
        case .noKeysFound:
            handleException(status: .unRegister, completion: completion)
        }
    }
    
    
    /// Helper method to execute signing, show biometric prompt.
    /// - Parameter userKey: User Information
    /// - Parameter authInterface: Interface to find the Authentication Type
    /// - Parameter completion: Completion block for Device binding result callback
    internal func authenticate(userKey: UserKey,
                               authInterface: DeviceAuthenticator,
                               _ completion: @escaping DeviceSigningResultCallback) {
        
        authInterface.initialize(userId: userKey.userId, prompt: Prompt(title: title, subtitle: subtitle, description: promptDescription))
        guard authInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        let startTime = Date()
        let timeout = timeout ?? 60
        
        do {
            // Authentication will be triggered during signing if necessary
            let jws = try authInterface.sign(userKey: userKey, challenge: challenge, expiration: getExpiration(timeout: timeout))
            
            // Check for timeout
            let delta = Date().timeIntervalSince(startTime)
            if(delta > Double(timeout)) {
                handleException(status: .timeout, completion: completion)
                return
            }
            
            // If no errors, set the input values and complete with success
            self.setJws(jws)
            
            completion(.success)
        } catch JOSESwiftError.localAuthenticationFailed {
            handleException(status: .abort, completion: completion)
        } catch let error as DeviceBindingStatus {
            handleException(status: error, completion: completion)
        } catch let error {
            handleException(status: .unknown(errorMessage: error.localizedDescription), completion: completion)
        }
    }
    
    
    /// Handle all the errors for the device binding.
    /// - Parameter status: Device binding status
    /// - Parameter completion: Completion block Device binding result callback
    open func handleException(status: DeviceBindingStatus, completion: @escaping DeviceSigningResultCallback) {
        setClientError(status.clientError)
        FRLog.e(status.errorMessage)
        completion(.failure(status))
    }
    
    
    //  MARK: - Set values
    
    /// Sets `jws` value in callback response
    /// - Parameter jws: String value of `jws`]
    public func setJws(_ jws: String) {
        self.inputValues[self.jwsKey] = jws
    }
    
    
    /// Sets `clientError` value in callback response
    /// - Parameter clientError: String value of `clientError`]
    public func setClientError(_ clientError: String) {
        self.inputValues[self.clientErrorKey] = clientError
    }
}
