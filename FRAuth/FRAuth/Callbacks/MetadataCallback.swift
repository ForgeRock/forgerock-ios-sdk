// 
//  MetadataCallback.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

open class MetadataCallback: Callback {
    
    public var _id: Int?
    
    //  MARK: - Init method
    
    /// Designated initialization method for MetadataCallback
    ///
    /// - Parameter json: JSON object of MetadataCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {
        
        
        guard let callbackType = json[CBConstants.type] as? String else {
            throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        if let callbackId = json[CBConstants._id] as? Int {
            self._id = callbackId
        }
        
        try super.init(json: [:])
        self.type = callbackType
        self.response = json
    }
    
    
    //  MARK: - Build
    
    /// Builds JSON request payload for the Callback
    ///
    /// - Returns: JSON request payload for the Callback
    public override func buildResponse() -> [String : Any] {
        return self.response
    }
}
