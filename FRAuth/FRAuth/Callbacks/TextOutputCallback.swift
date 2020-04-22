//
//  TextOutputCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 TextOutputCallback is a representation of TextOutputCallback Callback in OpenAM which provides a message to be displayed to a user with given message type.
 */
@objc(FRTextOutputCallback)
public class TextOutputCallback: Callback {
    
    //  MARK: - Property
    
    /// MessageType of Callback
    @objc
    public var messageType: MessageType
    /// String message to be displayed to a user
    @objc
    public var message: String
    
    
    //  MARK: - Init
    
    /// Designated initialization method for TextOutputCallback
    ///
    /// - Parameter json: JSON object of TextOutputCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    @objc
    required init(json: [String: Any]) throws {
        
        message = ""
        messageType = .unknown
        
        guard let callbackType = json["type"] as? String,
            let outputs = json["output"] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let outputName = output["name"] as? String, outputName == "message", let outputValue = output["value"] as? String {
                message = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "messageType", let messageTypeInt = output["value"] as? Int, let messageType = MessageType(rawValue: messageTypeInt) {
                self.messageType = messageType
            }
        }
        
        try super.init(json: json)
        
        if message.count == 0 || messageType == .unknown {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        self.type = callbackType
        self.response = json
    }
    
    
    //  MARK: - Build
    
    /// Builds JSON request payload for the Callback
    ///
    /// - Returns: JSON request payload for the Callback
    @objc
    open override func buildResponse() -> [String: Any] {
        return self.response
    }
}
