// 
//  DeviceSigningVerifierCallback.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import JOSESwift

/**
 * Callback to collect the device binding information
 */
open class DeviceSigningVerifierCallback: MultipleValuesCallback {
    
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
    /// Delegation to perform user selection in case of multiple keys
    public weak var delegate: DeviceSigningVerifierDelegate?
    
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
    
    
    /// Sign the device.
    /// - Parameter completion Completion block for Device binding result callback
    open func sign(completion: @escaping DeviceBindingResultCallback) {
        execute(userKeyService: nil, completion)
    }
    
    
    /// Helper method to execute binding , signing, show biometric prompt.
    /// - Parameter userKeyService: service to sort and fetch the keys stored in the device
    /// - Parameter completion: completion Completion block for Device binding result callback
    internal func execute(userKeyService: UserKeyService?,
                          _ completion: @escaping DeviceBindingResultCallback) {
        let newUserKeyService = userKeyService ?? UserDeviceKeyService(encryptedPreference: nil)
        
        let status = newUserKeyService.getKeyStatus(userId: userId)
        
        switch status {
        case .singleKeyFound(key: let key):
            authenticate(userKey: key, authInterface: nil, completion)
        case .multipleKeysFound(keys: _):
            getUserKey(userKeyService: newUserKeyService) { key in
                if let key = key {
                    self.authenticate(userKey: key, authInterface: nil, completion)
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
    /// - Parameter authInterface: Interface to find the Authentication Type - provide nil to default to getDeviceBindingAuthenticator()
    /// - Parameter completion: completion Completion block for Device binding result callback
    internal func authenticate(userKey: UserKey,
                               authInterface: DeviceAuthenticator?,
                               _ completion: @escaping DeviceBindingResultCallback) {
        let newAuthInterface = authInterface ?? getDeviceBindingAuthenticator(userKey: userKey)
        
        guard newAuthInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        let startTime = Date()
        let timeout = timeout ?? 60
        
        do {
            // Authentication will be triggered during signing if necessary
            let jws = try newAuthInterface.sign(userKey: userKey, challenge: self.challenge, expiration: self.getExpiration())
            
            // Check for timeout
            let delta = Date().timeIntervalSince(startTime)
            if(delta > Double(timeout)) {
                self.handleException(status: .timeout, completion: completion)
                return
            }
            
            // If no errors, set the input values and complete with success
            self.setJws(jws)
            
            completion(.success)
        } catch JOSESwiftError.localAuthenticationFailed {
            self.handleException(status: .abort, completion: completion)
        } catch let error {
            self.handleException(status: .unsupported(errorMessage: error.localizedDescription), completion: completion)
        }
    }
    
    
    /// Display fragment to select a user key from the list
    /// - Parameter userKeyService: service to sort and fetch the keys stored in the device
    /// - Parameter completion: Completion block for keys result
    open func getUserKey(userKeyService: UserKeyService,
                         completion: @escaping (UserKey?) -> (Void)) {
        if delegate == nil {
            delegate = self
        }
        delegate?.selectUserKey(userKeys: userKeyService.userKeys, selectionCallback: { selectedUserKey in
            completion(selectedUserKey)
        })
        
    }
    
    
    /// Handle all the errors for the device binding.
    /// - Parameter status: Device binding status
    /// - Parameter completion: Completion block Device binding result callback
    open func handleException(status: DeviceBindingStatus, completion: @escaping DeviceBindingResultCallback) {
        setClientError(status.clientError)
        FRLog.e(status.errorMessage)
        completion(.failure(status))
    }
    
    
    /// Create the interface for the Authentication type(biometricOnly, biometricAllowFallback, none)
    /// - Parameter userKey: selected UserKey from the device
    open func getDeviceBindingAuthenticator(userKey: UserKey) -> DeviceAuthenticator {
        return AuthenticatorFactory.getAuthenticator(userId: userKey.userId, authentication: userKey.authType, title: title, subtitle: subtitle, description: promptDescription, keyAware: nil)
    }
    
    
    /// Get Expiration date for the signed token, claim "exp" will be set to the JWS
    open func getExpiration() -> Date {
        return Date().addingTimeInterval(Double(timeout ?? 60))
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

extension DeviceSigningVerifierCallback: DeviceSigningVerifierDelegate { }
