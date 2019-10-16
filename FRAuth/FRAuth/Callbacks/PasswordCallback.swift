//
//  FRPasswordCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

/**
 PasswordCallback is a representation of OpenAM's PasswordCallback to collect single user input; PasswordCallback is typically used to collect user or OTP credentials for the authentication flow.
 */
@objc(FRPasswordCallback)
public class PasswordCallback: SingleValueCallback {
    
    //  MARK: - Init method
    
    /// Designated initialization method for PasswordCallback
    ///
    /// - Parameter json: JSON object of PasswordCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        try super.init(json: json)
        
        // Validate prompt value for the callback
        guard let _ = self.prompt else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
    }
}
