// 
//  DeviceBindingCallback.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
/**
 * Callback to collect the device binding information
 */
open class DeviceBindingCallback: MultipleValuesCallback {
    
    //  MARK: - Properties
    
    /// The userId received from server
    private(set) var userId: String!
    /// The userName received from server
    private(set) var userName: String!
    /// The challenge received from server
    private(set) var challenge: String!
    /// The authentication type of the journey
    private(set) var deviceBindingAuthenticationType: DeviceBindingAuthenticationType!
    // The title to be displayed in biometric prompt
    private(set) var title: String!
    // The subtitle to be displayed in biometric prompt
    private(set) var subtitle: String!
    // The description to be displayed in biometric prompt
    private(set) var promptDescription: String!
    // The timeout to be to expire the biometric authentication
    private(set) var timeout: Int?
    
    /// Jws input key in callback response
    private var jwsKey: String!
    /// Device name input key in callback response
    private var deviceNameKey: String!
    /// Device id input key in callback response
    private var deviceIdKey: String!
    /// Client Error input key in callback response
    private var clientErrorKey: String!
    
    //  MARK: - Init
    
    /// Designated initialization method for DeviceBindingCallback
    ///
    /// - Parameter json: JSON object of DeviceBindingCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required public init(json: [String : Any]) throws {
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]], let inputs = json[CBConstants.input] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.userId, let outputValue = output[CBConstants.value] as? String {
                userId = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.userName.lowercased(), let outputValue = output[CBConstants.value] as? String {
                userName = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.authenticationType, let outputValue = output[CBConstants.value] as? String, let outputEnumValue = DeviceBindingAuthenticationType(rawValue: outputValue) {
                deviceBindingAuthenticationType = outputEnumValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.challenge, let outputValue = output[CBConstants.value] as? String {
                challenge = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.title, let outputValue = output[CBConstants.value] as? String {
                title = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.subtitle, let outputValue = output[CBConstants.value] as? String {
                subtitle = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.description, let outputValue = output[CBConstants.value] as? String {
                promptDescription = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.timeout, let outputValue = output[CBConstants.value] as? Int {
                timeout = outputValue
            }
        }
        
        guard userId != nil, userName != nil, challenge != nil, deviceBindingAuthenticationType != nil, title != nil, subtitle != nil, promptDescription != nil else {
            throw AuthError.invalidCallbackResponse("Missing an output value")
        }
        
        for input in inputs {
            if let name = input[CBConstants.name] as? String, name.contains(CBConstants.jws) {
                self.jwsKey = name
            }
            else if let name = input[CBConstants.name] as? String, name.contains(CBConstants.deviceName) {
                self.deviceNameKey = name
            }
            else if let name = input[CBConstants.name] as? String, name.contains(CBConstants.deviceId) {
                self.deviceIdKey = name
            }
            else if let name = input[CBConstants.name] as? String, name.contains(CBConstants.clientError) {
                self.clientErrorKey = name
            }
        }
        
        guard jwsKey != nil, deviceNameKey != nil, deviceIdKey != nil, clientErrorKey != nil else {
            throw AuthError.invalidCallbackResponse("Missing an input value")
        }
        
        try super.init(json: json)
        
        self.type = callbackType
        self.response = json
    }
    
    
    /// Bind the device.
    /// - Parameter completion Completion block for Device binding result callback
    func bind(completion: @escaping DeviceBindingResultCallback) {
        execute(authInterface: nil, deviceId: nil, completion)
    }
    
    
    /// Helper method to execute binding , signing, show biometric prompt.
    /// - Parameter authInterface: Interface to find the Authentication Type - procide nil to default to getDeviceBindingAuthenticator()
    /// - Parameter deviceId: Interface to find the Authentication Type - provide nil to default to FRDevice.currentDevice?.identifier.getIdentifier()
    /// - Parameter completion: completion Completion block for Device binding result callback
    open func execute(authInterface: DeviceAuthenticator?,
                      deviceId: String?,
                      _ completion: @escaping DeviceBindingResultCallback) {
        
        let newAuthInterface = authInterface ?? getDeviceBindingAuthenticator()
        let newDeviceId = deviceId ?? FRDevice.currentDevice?.identifier.getIdentifier()
        
        guard newAuthInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        newAuthInterface.authenticate(timeout: timeout ?? 60) { result in
            
            do {
                switch result {
                case .success:
                    let kid = UUID().uuidString
                    let keyPair = try newAuthInterface.generateKeys()
                    let jws = try newAuthInterface.sign(keyPair: keyPair, kid: kid, userId: self.userId, challenge: self.challenge)
                    self.setJws(jws)
                    
                    if let newDeviceId = newDeviceId {
                        self.setDeviceId(newDeviceId)
                    }
                    
                    completion(.success)
                case .failure(let status):
                    self.handleException(status: status, completion: completion)
                }
            } catch {
                self.handleException(status: .unsupported(errorMessage: error.localizedDescription), completion: completion)
            }
        }
        
    }
    
    
    /// Handle all the errors for the device binding.
    /// - Parameter status: Device binding status
    /// - Parameter completion: Completion block Device binding result callback
    open func handleException(status: DeviceBindingStatus, completion: @escaping DeviceBindingResultCallback) {
        setClientError(status.clientError)
        FRLog.e(status.errorMessage)
        completion(.failure(status))
    }
    
    
    /// Ceate the interface for the Authentication type(biometricOnly, biometricAllowFallback, none)
    open func getDeviceBindingAuthenticator() -> DeviceAuthenticator {
        return AuthenticatorFactory.getAuthenticator(userId: userId, authentication: deviceBindingAuthenticationType, title: title, subtitle: subtitle, description: promptDescription, keyAware: nil)
    }
    
    
    //  MARK: - Set values
    
    /// Sets `jws` value in callback response
    /// - Parameter jws: String value of `jws`]
    public func setJws(_ jws: String) {
        self.inputValues[self.jwsKey] = jws
    }
    
    
    /// Sets `deviceName` value in callback response
    /// - Parameter deviceName: String value of `deviceName`]
    public func setDeviceName(_ deviceName: String) {
        self.inputValues[self.deviceNameKey] = deviceName
    }
    
    
    /// Sets `deviceId` value in callback response
    /// - Parameter deviceId: String value of `deviceId`]
    public func setDeviceId(_ deviceId: String) {
        self.inputValues[self.deviceIdKey] = deviceId
    }
    
    
    /// Sets `clientError` value in callback response
    /// - Parameter clientError: String value of `clientError`]
    public func setClientError(_ clientError: String) {
        self.inputValues[self.clientErrorKey] = clientError
    }
    
}


/// Convert authentication type string received from server to authentication type enum
enum DeviceBindingAuthenticationType: String, Codable {
    case biometricOnly = "BIOMETRIC_ONLY"
    case biometricAllowFallback = "BIOMETRIC_ALLOW_FALLBACK"
    case none = "NONE"
}
