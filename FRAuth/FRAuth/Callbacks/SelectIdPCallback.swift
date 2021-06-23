// 
//  SelectIdPCallback.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.

//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation


/**
 SelectIdPCallback is a representation of AM's `Select Identity Provider` Node to select a specific Identity Provider from given options (local authentication, or list of social login providers)
 */
public class SelectIdPCallback: SingleValueCallback {
    
    //  MARK: - Properties
    
    /// An array of Identity Provider value
    public var providers: [IdPValue]
    
    
    //  MARK: - Init
    
    /// Designated initialization method for SelectIdPCallback
    /// - Parameter json: JSON object of SelectIdPCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        var thisProvider: [IdPValue] = []
        
        //  Parse Identity Provider values from given JSON response
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.providers, let providers = output[CBConstants.value] as? [[String: Any]] {
                    for provider in providers {
                        
                        guard let providerId = provider[CBConstants.provider] as? String else {
                            throw AuthError.invalidCallbackResponse("Missing provider attribute")
                        }
                        
                        let uiConfig = provider[CBConstants.uiConfig] as? [String: String]
                        thisProvider.append(IdPValue(provider: providerId, uiConfig: uiConfig))
                    }
                }
            }
        }
        
        //  Set parsed array of providers
        self.providers = thisProvider
        try super.init(json: json)
    }
    
    
    //  MARK: - Public
    
    /// Sets a given provider to Callback input
    /// - Parameter provider: `IdPValue` to continue the authentication tree flow
    public func setProvider(provider: IdPValue) {
        self.setValue(provider.provider)
    }
}
