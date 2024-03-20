//
//  Node.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRCore

/**
 Node class is the core abstraction within an authentication tree. Trees are made up of nodes, which may modify the shared state and/or request input from the user via Callbacks. Node is also a representation of each step in the authentication flow, and keeps unique identifier and its state of the authentication flow. Node must be submitted to OpenAM to proceed or finish the authentication flow. Submitting the Node object returns one of following:
 * Result of expected type, if available
 * Another Node object instance to continue on the authentication flow
 * An error, if occurred during the authentication flow
 */
@objc(FRNode)
public class Node: NodeNext {

    //  MARK: - Public properties
    
//    /// A list of Callback for the state
//    @objc public var callbacks: [Callback] = []
//    /// authId for the authentication flow
//    @objc public var authId: String
//    /// Unique UUID String value of initiated AuthService flow
//    @objc public var authServiceId: String
    /// Stage attribute in Page Node
    @objc public var stage: String?
    /// Header attribute in Page Node
    @objc public var pageHeader: String?
    /// Description attribute in Page Node
    @objc public var pageDescription: String?
    /// Designated AuthService name defined in OpenAM
//    var serviceName: String
//    /// authIndexType value in AM
//    var authIndexType: String
//    /// ServerConfig information for AuthService/Node API communication
//    var serverConfig: ServerConfig
//    /// OAuth2Client information for AuthService/Node API communication
//    var oAuth2Config: OAuth2Client?
//    /// TokenManager instance to manage, and persist authenticated session
//    var tokenManager: TokenManager?
//    /// KeychainManager instance to persist, and retrieve credentials from storage
//    var keychainManager: KeychainManager?
    
    
    
    //  MARK: - Init
    
    /// Designated initialization method for Node; AuthService process will initialize Node with given response from OpenAM
    /// - Parameters:
    ///   - authServiceId: Unique UUID for current AuthService flow
    ///   - authServiceResponse: JSON response object of AuthService in OpenAM
    ///   - serverConfig: ServerConfig object for AuthService/Node communication
    ///   - serviceName: Service name for AuthService (TreeName)
    ///   - authIndexType: authIndexType value in AM (default to 'service')
    ///   - oAuth2Config: (Optional) OAuth2Client object for AuthService/Node communication for abstraction layer
    ///   - keychainManager: KeychainManager instance to persist, and retrieve credentials from secure storage
    ///   - tokenManager: TokenManager  instance to manage and persist authenticated session
    /// - Throws: `AuthError`
    init?(_ authServiceId: String, _ authServiceResponse: [String: Any], _ serverConfig: ServerConfig, _ serviceName: String, _ authIndexType: String, _ oAuth2Config: OAuth2Client? = nil, _ keychainManager: KeychainManager? = nil, _ tokenManager: TokenManager? = nil) throws {
        
        super.init()
        
        guard let authId = authServiceResponse[OpenAM.authId] as? String else {
            FRLog.e("Invalid response: missing 'authId'")
            throw AuthError.invalidAuthServiceResponse("missing or invalid 'authId'")
        }
        
        self.authServiceId = authServiceId
        self.stage = authServiceResponse[OpenAM.stage] as? String
        self.pageHeader = authServiceResponse[OpenAM.header] as? String
        self.pageDescription = authServiceResponse[OpenAM.description] as? String
        self.serverConfig = serverConfig
        self.serviceName = serviceName
        self.authIndexType = authIndexType
        self.oAuth2Config = oAuth2Config
        self.authId = authId
        
        self.keychainManager = keychainManager
        self.tokenManager = tokenManager
        
        if let callbacks = authServiceResponse[OpenAM.callbacks] as? [[String: Any]] {
            
            for callback in callbacks {
                
                // Validate if callback response contains type
                guard var callbackType = callback["type"] as? String else {
                    FRLog.e("Invalid response: Callback is missing 'type' \n\t\(callback)")
                    throw AuthError.invalidCallbackResponse(String(describing: callback))
                }
                
                //  Validate if Callback is WebAuthnCallback
                let webAuthnType = WebAuthnCallback.getWebAuthnType(callback)
                switch webAuthnType {
                //  If Callback type is WebAuthnAuthentication/Registration, manually change Callback type
                case .authentication, .registration:
                    callbackType = webAuthnType.rawValue
                    break
                default:
                    break
                }
                
                let callbackObj = try Node.transformCallback(callbackType: callbackType, json: callback)
                self.callbacks.append(callbackObj)
                
                if self.stage == nil { //Fix for SDKS-1209
                    // Support AM 6.5.2 stage property workaround with MetadataCallback
                    if let metadataCallback = callbackObj as? MetadataCallback, let outputs = metadataCallback.response[CBConstants.output] as? [[String: Any]] {
                        for output in outputs {
                            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.data, let outputValue = output[CBConstants.value] as? [String: String] {
                                self.stage = outputValue[CBConstants.stage]
                            }
                        }
                    }
                }
            }
        }
        else {
            FRLog.e("Invalid response: missing or invalid callback attribute \n\t\(authServiceResponse)")
            throw AuthError.invalidAuthServiceResponse("missing or invalid callback(S) response \(authServiceResponse)")
        }
    }

    
    //  MARK: - Static helper method
    
    /// Converts given JSON into Callback object
    /// - Parameters:
    ///   - callbackType: String value of Callback type
    ///   - json: JSON response of Callback
    /// - Throws: `AuthError`
    /// - Returns: Callback object
    static func transformCallback(callbackType: String, json: [String: Any]) throws -> Callback {

        // Validate if given callback type is supported
        guard let callbackClass = CallbackFactory.shared.supportedCallbacks[callbackType] else {
            FRLog.e("Unsupported callback: Callback is not supported in SDK \n\t\(json)")
            throw AuthError.unsupportedCallback("callback type, \(callbackType), is not supported")
        }
        
        let callback = try callbackClass.init(json: json)
        
        return callback
    }
    
    // - MARK: Objective-C Compatibility
    
    @objc(nextWithUserCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithUserCompletion(completion:@escaping NodeCompletion<FRUser>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithAccessTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithAccessTokenCompletion(completion:@escaping NodeCompletion<AccessToken>) {
        self.next(completion: completion)
    }
    
    
    @objc(nextWithTokenCompletion:)
    @available(swift, obsoleted: 1.0)
    public func nextWithTokenCompletion(completion:@escaping NodeCompletion<Token>) {
        self.next(completion: completion)
    }
}
