// 
//  WebAuthnCallback.swift
//  FRAuth
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation


/// WebAuthnCallback represents AM's WebAuthn MetadataCallback, and is a parent class of WebAuthnRegistrationCallback and WebAuthnAuthenticationCallback
open class WebAuthnCallback: MetadataCallback {
    
    //  MARK: - Static internal helper methods
    
    /// Extracts WebAuthn type from given MetadataCallback
    /// - Parameter json: raw JSON payload for MetdataCallback
    /// - Returns: WebAuthnType enum
    static func getWebAuthnType(_ json: [String: Any]) -> WebAuthnCallbackType {
    
        guard let callbackType = json[CBConstants.type] as? String, callbackType == CallbackType.MetadataCallback.rawValue else {
            return .invalid
        }
        
        if let outputs = json[CBConstants.output] as? [[String: Any]] {
            for output in outputs {
                //  If output attribute contains `data` attribute, and within `data` attribute, if it contains `relyingPartyId`, then it is `WebAuthnCallback`
                if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.data, let outputValue = output[CBConstants.value] as? [String: Any], let outputType = outputValue[CBConstants._type] as? String, outputType == CBConstants.WebAuthn {
                    
                    if let outputAction = outputValue[CBConstants._action] as? String {
                        //  If _action exists, AM 7.1.0 response
                        if outputAction == CBConstants.webauthn_registration {
                            return .registration
                        } else if outputAction == CBConstants.webauthn_authentication {
                            return .authentication
                        } else {
                            return .invalid
                        }
                    }
                    else {
                        //  If `data` attribute contains `pubKeyCredParams`, then consider this as registration
                        if outputValue.keys.contains(CBConstants.pubKeyCredParams) {
                            return .registration
                        }
                        else {
                            //  Otherwise, authentication
                            return .authentication
                        }
                    }
                }
            }
        }
        
        return .invalid
    }
    
    
    /// Extracts AM 7.0.0's Int8 array value
    /// - Parameter query: Entire String response of AM 7.0.0's Int8 array
    /// - Returns: An array of String values each representing Int8Array
    static func convertInt8Arr(query: String) -> [String] {
        let regex = try! NSRegularExpression(pattern:"\\Int8Array\\(\\[(.*?)\\]\\)", options: [])
        var results = [String]()

        regex.enumerateMatches(in: query, options: [], range: NSMakeRange(0, query.utf16.count)) { result, flags, stop in
            if let r = result?.range(at: 1), let range = Range(r, in: query) {
                results.append(String(query[range]))
            }
        }
        
        return results
    }
    
    
    //  MARK: - Instance helper methods
    
    /// Sets WebAuthn outcome to designated HiddenValueCallback
    /// - Parameters:
    ///   - node: Current Node object contains HiddenValueCallback
    ///   - outcome: String value of WebAuthn outcome
    func setWebAuthnOutcome(node: Node, outcome: String) {
        for callback in node.callbacks {
            if let hiddenValueCallback = callback as? HiddenValueCallback, hiddenValueCallback.isWebAuthnOutcome {
                hiddenValueCallback.setValue(outcome)
                return
            }
        }
        FRLog.e("Failed to set WebAuthn outcome to HiddenValueCallback; HiddenValueCallback with 'webAuthnOutcome' is missing", subModule: WebAuthn.module)
    }
    
    
    /// Converts Int8 array into String representation of Int8
    /// - Parameter arr: Int8 array to be converted into String value
    /// - Returns: String value of Int8 array
    func convertInt8ArrToStr(_ arr: [Int8]) -> String {
        var str = ""
        for (index, byte) in arr.enumerated() {
            str = str + "\(byte)"
            if index != (arr.count - 1) {
                str = str + ","
            }
        }
        return str
    }
}
