//
//  TextInputCallback.swift
//  FRAuth
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 TextInputCallback is a representation of OpenAM's TextInputCallback to collect single user input; It is typically used to collect any text input for the authentication flow.
 */
@objc(FRTextInputCallback)
public class TextInputCallback: SingleValueCallback {
    
    private var defaultText: String?
    
    //  MARK: - Init
    
    /// Designated initialization method for TextInputCallback
    ///
    /// - Parameter json: JSON object of TextInputCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        try super.init(json: json)
        
        // Validate prompt value for the callback
        guard let _ = self.prompt else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output[CBConstants.name] as? String, let outputValue = output[CBConstants.value] as? String, outputName == CBConstants.defaultText {
                    self.defaultText = outputValue
                }
            }
        }
    }
    
    public func getDefaultText() -> String? {
        return self.defaultText
    }
    
    public func setValue(_ val: String) {
        self._value = val
    }
}
