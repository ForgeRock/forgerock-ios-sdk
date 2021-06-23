//
//  PollingWaitCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 PollingWaitCallback is a representation of a PollingWaitCallback Callback Object in OpenAM which instructs an application to wait for the given period and resubmit the request.
 */
@objc(FRPollingWaitCallback)
public class PollingWaitCallback: Callback {
    
    //  MARK: - Property
    
    /// The period of time in milliseconds that the client should wait before replying to this callback
    @objc
    public var waitTime: Int
    /// The message which should be displayed to the user
    @objc
    public var message: String
    
    
    //  MARK: - Init
    
    /// Designated initialization method for PollingWaitCallback
    ///
    /// - Parameter json: JSON object of PollingWaitCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    @objc
    required init(json: [String: Any]) throws {
        
        waitTime = -1
        message = ""
        
        guard let callbackType = json[CBConstants.type] as? String,
              let outputs = json[CBConstants.output] as? [[String: Any]] else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            
            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.waitTime, let outputValueStr = output[CBConstants.value] as? String, let outputValue = Int(outputValueStr) {
                
                waitTime = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.message, let outputValue = output[CBConstants.value] as? String {
                
                message = outputValue
            }
        }
        
        try super.init(json: json)
        
        if waitTime == -1 || message.count == 0 {
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
