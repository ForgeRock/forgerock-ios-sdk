//
//  PolicyAdviceCreator.swift
//  FRAuth
//
//  Copyright (c) 2023-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// PolicyAdviceCreator helps create a Authorization PolicyAdvice based on different response types (xml, base64XML, json) that receive from AM's policy engine
public class PolicyAdviceCreator {

    private let adviceKey = "advices"
    private let valueKey = "authIndexValue"
    private let typeKey = "authIndexType"
    
    //  MARK: - Init
    
    /// Initializes PolicyAdviceCreator object
    public init() {}
    
    /// Parse the advice json
    /// - Parameters:
    ///   - advice: The Advice in key value form
    /// - Returns: The parsed PolicyAdvice
    public func parseAsBase64(advice: String) -> PolicyAdvice? {
        var dict: [String: String] = [:]
        let regex = try? NSRegularExpression(pattern: "^\"|\"$", options: [])
        advice.components(separatedBy: ",").forEach { value in
            let componenets = value.components(separatedBy: "=")
            if(componenets.count >= 2 ) {
                dict[componenets[0]] = regex?.stringByReplacingMatches(in: componenets[1], range: NSMakeRange(0, componenets[1].count), withTemplate: "")
            }
        }
        guard let advices = dict[adviceKey], let decodedAdvices = advices.decodeURL(),
              let adviceDict = try? JSONSerialization.jsonObject(with: decodedAdvices, options: []) as? [String: Any] else {
            return nil
        }
       return PolicyAdvice(json: adviceDict)
    }
    
    /// Parse the advice json
    /// - Parameters:
    ///   - advice: The Advice in XML or base64 encoded form
    /// - Returns: The parsed PolicyAdvice
    public func parse(advice: String) -> PolicyAdvice? {
        guard let urlString = URL(string: advice), let authIndexValue = urlString.valueOf(valueKey), let authIndexType = urlString.valueOf(typeKey) else {
            return nil
        }

        // Try Parse the XML.
        guard let result = parseXML(advice: authIndexValue) else {
            //On Failure Decode and parse the XML
            return decodeAndParseXML(authIndexType: authIndexType,
                                     authIndexValue: authIndexValue)
        }
        return PolicyAdvice(type: result.0,
                            value: result.1,
                            authIndexType: authIndexType,
                            authIndexValue: authIndexValue)
    }
    
    private func decodeAndParseXML(authIndexType: String,
                                   authIndexValue: String) -> PolicyAdvice? {
        guard let data = authIndexValue.decodeURL(),
                let decodeXML = String(data: data, encoding: .utf8),
                let result = parseXML(advice: decodeXML) else { return nil }
        
        return PolicyAdvice(type: result.0,
                            value: result.1,
                            authIndexType: authIndexType,
                            authIndexValue: decodeXML)
    }

    private func parseXML(advice: String) -> (String, String)? {
        guard let valueRange = advice.range(of: #"(?<=\<Value\>).*?(?=\<\/Value\>)"#, options: .regularExpression), let nameRange = advice.range(of: #"(?<=\<Attribute name=\").*?(?=\")"#, options: .regularExpression) else {
            return nil
        }
        return (String(advice[nameRange]), String(advice[valueRange]))
    }
}
