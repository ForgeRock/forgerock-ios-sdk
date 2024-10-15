//
//  DeviceBindingCallback.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import JOSESwift
import FRCore
import FRAuth

/**
 * Callback to collect the device binding information
 */
open class DeviceBindingCallback: MultipleValuesCallback, Binding {
    
    //  MARK: - Properties
    
    /// The userId received from server
    public private(set) var userId: String
    /// The userName received from server
    public private(set) var userName: String
    /// The challenge received from server
    public private(set) var challenge: String
    /// The authentication type of the journey
    public private(set) var deviceBindingAuthenticationType: DeviceBindingAuthenticationType
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
    /// Device name input key in callback response
    private var deviceNameKey: String
    /// Device id input key in callback response
    private var deviceIdKey: String
    /// Client Error input key in callback response
    private var clientErrorKey: String
    
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
        
        // parse outputs
        var outputDictionary = [String: Any]()
        for output in outputs {
            guard let outputName = output[CBConstants.name] as? String, let outputValue = output[CBConstants.value] else {
                throw AuthError.invalidCallbackResponse("Failed to parse output")
            }
            outputDictionary[outputName] = outputValue
        }
        
        guard let userId = outputDictionary[CBConstants.userId] as? String else {
            throw AuthError.invalidCallbackResponse("Missing userId")
        }
        self.userId = userId
        
        guard let userName = outputDictionary[CBConstants.username] as? String else {
            throw AuthError.invalidCallbackResponse("Missing username")
        }
        self.userName = userName
        
        guard let outputValue = outputDictionary[CBConstants.authenticationType] as? String, let deviceBindingAuthenticationType = DeviceBindingAuthenticationType(rawValue: outputValue) else {
            throw AuthError.invalidCallbackResponse("Missing authenticationType")
        }
        self.deviceBindingAuthenticationType = deviceBindingAuthenticationType
        
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
        
        guard let deviceNameKey = inputNames.filter({ $0.contains(CBConstants.deviceName) }).first else {
            throw AuthError.invalidCallbackResponse("Missing deviceNameKey")
        }
        self.deviceNameKey = deviceNameKey
        
        guard let deviceIdKey = inputNames.filter({ $0.contains(CBConstants.deviceId) }).first else {
            throw AuthError.invalidCallbackResponse("Missing deviceIdKey")
        }
        self.deviceIdKey = deviceIdKey
        
        guard let clientErrorKey = inputNames.filter({ $0.contains(CBConstants.clientError) }).first else {
            throw AuthError.invalidCallbackResponse("Missing clientErrorKey")
        }
        self.clientErrorKey = clientErrorKey
        
        try super.init(json: json)
        type = callbackType
        response = json
    }
    
    
    /// Bind the device.
    /// - Parameter deviceAuthenticator: method for providing a ``DeviceAuthenticator`` from ``DeviceBindingAuthenticationType`` - defaults value is `deviceAuthenticatorIdentifier`
    /// - Parameter prompt: Biometric prompt to override the server values
    /// - Parameter completion: Completion block for Device binding result callback
    open func bind(deviceAuthenticator: ((DeviceBindingAuthenticationType) -> DeviceAuthenticator)? = nil,
                   prompt: Prompt? = nil,
                   completion: @escaping DeviceBindingResultCallback) {
        let authInterface = deviceAuthenticator?(deviceBindingAuthenticationType) ?? deviceAuthenticatorIdentifier(deviceBindingAuthenticationType)
        
        let dispatchQueue = DispatchQueue(label: "com.forgerock.serialQueue", qos: .userInitiated)
        dispatchQueue.async {
            self.execute(authInterface: authInterface, prompt: prompt, completion)
        }
    }
    
    
    /// Helper method to execute binding , signing, show biometric prompt.
    /// - Parameter authInterface: Interface to find the Authentication Type - default value is ``getDeviceAuthenticator(type: deviceBindingAuthenticationType)``
    /// - Parameter deviceId: Interface to find the Authentication Type - default value is `FRDevice.currentDevice?.identifier.getIdentifier()`
    /// - Parameter deviceRepository: Storage for user keys - default value is ``LocalDeviceBindingRepository()``
    /// - Parameter prompt: Biometric prompt to override the server values
    /// - Parameter completion: Completion block for Device binding result callback
    internal func execute(authInterface: DeviceAuthenticator? = nil,
                          deviceId: String? = nil,
                          deviceRepository: DeviceBindingRepository = LocalDeviceBindingRepository(),
                          prompt: Prompt? = nil,
                          _ completion: @escaping DeviceBindingResultCallback) {
        if deviceBindingAuthenticationType != .none {
#if targetEnvironment(simulator)
            // DeviceBinding/Signing other than `.NONE` type is not supported on the iOS Simulator
            handleException(status: .unsupported(errorMessage: "DeviceBinding/Signing is not supported on the iOS Simulator"), completion: completion)
            return
#endif
        }
        
        let authInterface = authInterface ?? getDeviceAuthenticator(type: deviceBindingAuthenticationType)
        authInterface.initialize(userId: userId, prompt: prompt ?? Prompt(title: title, subtitle: subtitle, description: promptDescription))
        let deviceId = deviceId ?? FRDevice.currentDevice?.identifier.getIdentifier()
        
        guard authInterface.isSupported() else {
            handleException(status: .unsupported(errorMessage: nil), completion: completion)
            return
        }
        
        let startTime = Date()
        let timeout = timeout ?? 60
        var userKey: UserKey? = nil
        
        do {
            let keyPair = try authInterface.generateKeys()
            userKey = UserKey(id: keyPair.keyAlias, userId: userId, userName: userName, kid: UUID().uuidString, authType: deviceBindingAuthenticationType, createdAt: Date().timeIntervalSince1970)
            guard let userKey = userKey else {
                throw DeviceBindingStatus.unsupported(errorMessage: "Cannot create userKey")
            }
            try deviceRepository.persist(userKey: userKey)
            // Authentication will be triggered during signing if necessary
            let jws = try authInterface.sign(keyPair: keyPair, kid: userKey.kid, userId: userId, challenge: challenge, expiration: getExpiration(timeout: timeout))
            
            // Check for timeout
            let delta = Date().timeIntervalSince(startTime)
            if(delta > Double(timeout)) {
                deleteUserKey()
                handleException(status: .timeout, completion: completion)
                return
            }
            
            // If no errors, set the input values and complete with success
            setJws(jws)
            if let deviceId = deviceId {
                setDeviceId(deviceId)
            }
            completion(.success)
        } catch JOSESwiftError.localAuthenticationFailed {
            deleteUserKey()
            handleException(status: .abort, completion: completion)
        } catch let error as DeviceBindingStatus {
            deleteUserKey()
            handleException(status: error, completion: completion)
        } catch {
            deleteUserKey()
            handleException(status: .abort, completion: completion)
        }
        
        func deleteUserKey() {
            if let userKey = userKey {
                try? deviceRepository.delete(userKey: userKey)
            }
            authInterface.deleteKeys()
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
    
    open func getDeviceAuthenticator(type: DeviceBindingAuthenticationType) -> DeviceAuthenticator {
        return type.getAuthType()
    }
    
    open func getExpiration(timeout: Int?) -> Date {
        return Date().addingTimeInterval(Double(timeout ?? 60))
    }
    
    open var deviceAuthenticatorIdentifier: (DeviceBindingAuthenticationType) -> DeviceAuthenticator {
        get {
            return getDeviceAuthenticator(type:)
        }
    }
}
