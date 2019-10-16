//
//  FRNameCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 NameCallback is a representation of OpenAM's NameCallback to collect single user input; NameCallback is typically used to collect Username for the authentication flow.
 */
@objc(FRNameCallback)
public class NameCallback: SingleValueCallback {
    
    //  MARK: - Init 
    
    /// Designated initialization method for NameCallback
    ///
    /// - Parameter json: JSON object of NameCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        try super.init(json: json)
        
        // Validate prompt value for the callback
        guard let _ = self.prompt else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
    }
}
