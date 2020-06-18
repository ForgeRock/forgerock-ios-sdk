//
//  FRCallback.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/**
 Callback class is base class, and is a representation of Callback implementation that OpenAM presents as par to of authentication flow.
 All Callback class **must** inherit from this class, and implement its own logic to handle interaction(s) with OpenAM.
 
 ## Important Note ##
 All inherited Callback class **must** implement and override following method as Callback is just a base class implementation due to Objective-C compatibility:
    * *init* method that parses raw JSON response, and assign any value accordingly to its properties
    * *buildResponse()* method that prepares, and builds request JSON payload for this specific Callback
 */
@objc(FRCallback)
open class Callback: NSObject {
    
    //  MARK: - Property
    
    /// String value of Callback type
    @objc
    open var type: String = ""
    
    /// Raw JSON response of Callback
    @objc
    open var response: [String: Any] = [:]
    
    
    //  MARK: - Init
    
    /// Constructs Callback object with raw JSON object, and allocates any required value to its instance properties accordingly
    ///
    /// - Parameter json: Raw JSON response of the Callback
    /// - Throws: AuthError when invalid Callback response is passed, or missing required value for the callback
    @objc
    required public init(json: [String: Any]) throws {
        self.response = json
    }
    
    
    //  MARK: - Build
    
    /// Builds JSON request payload for the Callback
    ///
    /// - Returns: JSON request payload for the Callback
    @objc
    open func buildResponse() -> [String: Any] {
        return [:]
    }
}
