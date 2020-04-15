// 
//  DeviceProfileCallback.swift
//  FRAuth
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// DeviceAttributeCallback is a callback class that collects Device Information using DeviceCollector(s) in FRAuth SDK.
@objc public class DeviceProfileCallback: HiddenValueCallback, ActionCallback {
    
    //  MARK: - Properties
    
    /// Boolean indicator whether device metadata is required or not
    @objc public var metadataRequired: Bool = false
    /// Boolean indicator whether device location is required or not
    @objc public var locationRequired: Bool = false
    /// Message of device profile collector callback
    @objc public var message: String = ""
    
    //  MARK: - Init
    
    /// Designated initialization method for HiddenValueCallback
    ///
    /// - Parameter json: JSON object of HiddenValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        guard let outputs = json["output"] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let outputName = output["name"] as? String, outputName == "location", let outputValue = output["value"] as? Bool {
                locationRequired = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "metadata", let outputValue = output["value"] as? Bool {
                metadataRequired = outputValue
            }
            else if let outputName = output["name"] as? String, outputName == "message", let outputValue = output["value"] as? String {
                message = outputValue
            }
        }
        
        try super.init(json: json)
        
        // For now, force Callback.type as DeviceAttributeCallback
        type = "DeviceAttributeCallback"
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
        
        if locationRequired {
            if let locationCollector = locationCollector {
                collector.collectors.append(locationCollector)
            }
            else {
                FRLog.w("LocationCollector is not found during DeviceAttributeCallback.execute")
            }
        }
        
        if metadataRequired {
            collector.collectors.append(profileCollector)
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
