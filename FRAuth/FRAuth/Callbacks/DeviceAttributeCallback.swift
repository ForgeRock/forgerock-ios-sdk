// 
//  DeviceAttributeCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// DeviceAttributeCallback is a callback class that collects Device Information using DeviceCollector(s) in FRAuth SDK.
@objc public class DeviceAttributeCallback: HiddenValueCallback, ActionCallback {
    
    //  MARK: - Properties
    
    /// List of attributes to be collected
    @objc public var attributes: [String] = []
    
    //  MARK: - Init
    
    /// Designated initialization method for HiddenValueCallback
    ///
    /// - Parameter json: JSON object of HiddenValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        try super.init(json: json)
        
        // For now, force Callback.type as DeviceAttributeCallback
        type = "DeviceAttributeCallback"
        
        if let idUrlString = id, let idUrl = URLComponents(string: idUrlString), let queryItems = idUrl.queryItems {
            for queryItem in queryItems {
                if queryItem.name == "attributes", let queryValue = queryItem.value {
                    attributes.append(queryValue)
                }
            }
        }
    }
    
    
    /// Executes list of DeviceCollector to collect device information based on DeviceAttributeCallback's attributes
    /// - Parameter completion: Completion block that returns JSON of collected information
    public func execute(_ completion: @escaping JSONCompletionCallback) {
        let collector = FRDeviceCollector()
        collector.collectors.removeAll()
        var locationCollector: DeviceCollector?
        
        let profileCollector = ProfileCollector()
        
        for deviceCollector in FRDeviceCollector.shared.collectors {
            if String(describing: deviceCollector) == "FRProximity.LocationCollector" {
                locationCollector = deviceCollector
            }
            else if String(describing: deviceCollector) == "FRProximity.BluetoothCollector" {
                profileCollector.collectors.append(deviceCollector)
            }
        }
        
        
        for attribute in attributes {
            if attribute.lowercased() == "location" {
                if let locationCollector = locationCollector {
                    collector.collectors.append(locationCollector)
                }
                else {
                    FRLog.w("LocationCollector is not found during DeviceAttributeCallback.execute")
                }
            }
            else if attribute.lowercased() == "profile" {
                collector.collectors.append(profileCollector)
            }
        }
        
        collector.collect { (json) in
            self.value = self.JSONStringify(value: json as AnyObject)
            completion(json)
        }
    }
    
    
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : nil
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: options ?? []) {
                if let string = String(data: data, encoding: String.Encoding.utf8) {
                    return string
                }
            }
        }
        return ""
    }
}
