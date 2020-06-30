// 
//  PolicyAdvice.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// AdviceType of AM's policy engine; currently only supports: TransactionConditionAdvice | AuthenticateToServiceConditionAdvice
public enum AdviceType: String {
    case transactionCondition = "TransactionConditionAdvice"
    case authenticateToService = "AuthenticateToServiceConditionAdvice"
//    case authScheme = "AuthSchemeConditionAdvice"
//    case authLevel = "AuthLevelConditionAdvice"
//    case authenticateToRealm = "AuthenticateToRealmConditionAdvice"
}

/// PolicyAdvice is a representation of Authorization Policy advice response from AM's policy engine
@objc public class PolicyAdvice: NSObject {
    
    //  MARK: - Property
    
    /// AdviceType of the PolicyAdvice
    public var type: AdviceType
    /// Advice value (transactionId, or AuthenticationTree name)
    public var value: String
    /// Optional transactionId; only available for transactional authorization
    public var txId: String?
    
    /// populated authIndexValue for Authentication Tree
    var authIndexValue: String
    /// populated authIndexType for Authentication Tree; defualted to composite_advice
    var authIndexType: String
    
    
    //  MARK: - Init
    
    /// Initializes PolicyAdvice object with URL; PolicyAdvice class extracts certain information fromt he redirect-url, and construct the object
    /// - Parameter redirectUrl: redirectURL string value from the response header
    @objc public init?(redirectUrl: String) {
        guard let url = URL(string: redirectUrl), let xmlstring = url.valueOf("authIndexValue"), let authIndexType = url.valueOf("authIndexType") else {
            return nil
        }
        
        self.authIndexType = authIndexType
        self.authIndexValue = xmlstring

        if let range = xmlstring.range(of: #"(?<=\<Value\>).*?(?=\<\/Value\>)"#, options: .regularExpression) {
            value = String(xmlstring[range])
        } else {
            return nil
        }

        if let range = xmlstring.range(of: #"(?<=\<Attribute name=\").*?(?=\")"#, options: .regularExpression), let adviceType = AdviceType(rawValue: String(xmlstring[range])) {
            type = adviceType
        } else {
            return nil
        }
        
        if type == .transactionCondition {
            txId = value
        }
    }
    
    
    /** Initializes PolicyAdvice object with JSON payload; JSON playload should be in following format and should be the same format that AM returns for policy evaluation.
      ````
     {
        "resource": "http://www.example.com:8000/index.html",
        "actions": {},
        "attributes": {},
        "advices": {
            "TransactionConditionAdvice": [
                "9dae2c80-fe7a-4a36-b57b-4fb1271b0687"
            ]
        },
        "ttl": 0
     }
      ````
     - Parameter json: JSON payload of AM's policy evaluation response
        **/
    @objc public init?(json: [String: Any]) {

        var advices: [String: Any]? = nil
        
        if let advicesJSON = json["advices"] as? [String: Any], advicesJSON.keys.count > 0 {
            advices = advicesJSON
        }
        
        if let advices = advices, let adviceKey = advices.keys.first, let adviceValues = advices[adviceKey] as? [String], let adviceValue = adviceValues.first, let adviceType = AdviceType(rawValue: adviceKey) {

            authIndexType = OpenAM.compositeAdvice
            authIndexValue = "<Advices><AttributeValuePair><Attribute name=\"\(adviceType.rawValue)\"/><Value>\(adviceValue)</Value></AttributeValuePair></Advices>"
            type = adviceType
            value = adviceValue

            if type == .transactionCondition {
                txId = value
            }
        }
        else {
            return nil
        }
    }
    
    
    /** Initializes PolicyAdvice object with authorization policy type, and value.
     With example JSON payload shown below, 'TransactionConditionAdvice' is type of PolicyAdvice, and '9dae2c80-fe7a-4a36-b57b-4fb1271b0687' is value of PolicyAdvice
     ````
     {
        "resource": "http://www.example.com:8000/index.html",
        "actions": {},
        "attributes": {},
        "advices": {
            "TransactionConditionAdvice": [
                "9dae2c80-fe7a-4a36-b57b-4fb1271b0687"
            ]
        },
        "ttl": 0
     }
      ````
     - Parameter type: Type of authorization policy in string; 'TransactionConditionAdvice' or 'AuthenticateToServiceConditionAdvice'
     - Parameter value: String value of authorization policy; (i.e. transactionId, or Authentication Tree name)
     **/
    @objc public init?(type: String, value: String) {
        
        guard let adviceType = AdviceType(rawValue: type) else {
            FRLog.w("Failed to parse AdviceType string value")
            return nil
        }
        
        authIndexType = OpenAM.compositeAdvice
        authIndexValue = "<Advices><AttributeValuePair><Attribute name=\"\(adviceType.rawValue)\"/><Value>\(value)</Value></AttributeValuePair></Advices>"
        self.type = adviceType
        self.value = value

        if self.type == .transactionCondition {
            txId = value
        }
    }
}
