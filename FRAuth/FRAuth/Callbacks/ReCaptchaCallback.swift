//
//  ReCaptchaCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 ReCaptchaCallback is a representation of ReCaptchaCallback Callback in OpenAM which provides ReCaptcha credentials to process ReCaptcha in native application.
 */
@objc(FRReCaptchaCallback)
public class ReCaptchaCallback: Callback {
    
    //  MARK: - Property
    
    /// String value of inputName of the callback
    @objc
    public var inputName: String?
    /// Value of ReCaptcah result
    @objc
    public var value: Any?
    /// String value of ReCaptcha SiteKey
    @objc
    public var recaptchaSiteKey: String
    
    
    //  MARK: - Init
    
    /// Designated initialization method for ReCaptchaCallback
    ///
    /// - Parameter json: JSON object of ReCaptchaCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    @objc
    required init(json: [String: Any]) throws {
        
        recaptchaSiteKey = ""
        
        guard let callbackType = json[CBConstants.type] as? String,
              let outputs = json[CBConstants.output] as? [[String: Any]],
              let inputs = json[CBConstants.input] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for input in inputs {
            if let inputName = input[CBConstants.name] as? String {
                self.inputName = inputName
            }
            if let inputValue = input[CBConstants.value] as? String {
                self.value = inputValue
            }
        }
        
        for output in outputs {
            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.recaptchaSiteKey, let outputValue = output[CBConstants.value] as? String {
                recaptchaSiteKey = outputValue
            }
        }
        
        try super.init(json: json)
        
        if recaptchaSiteKey.count == 0 {
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
    public override func buildResponse() -> [String : Any] {
        var responsePayload = self.response
        responsePayload[CBConstants.input] = [[CBConstants.name: self.inputName, CBConstants.value: self.value]]
        return responsePayload
    }
}
