// 
//  DeviceProfileCallback.swift
//  FRAuth
//
//  Copyright (c) 2020-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

/// DeviceProfileCallback is a callback class that collects Device Information using DeviceCollector(s) in FRAuth SDK.
@objc public class DeviceProfileCallback: HiddenValueCallback, ActionCallback {
    
    //  MARK: - Properties
    
    /// Boolean indicator whether device metadata is required or not
    @objc public var metadataRequired: Bool = false
    /// Boolean indicator whether device location is required or not
    @objc public var locationRequired: Bool = false
    /// Message of device profile collector callback
    @objc public var message: String = ""
    
    public var locationCollector: DeviceCollector?
    public var profileCollector: ProfileCollector = ProfileCollector()
    public var collector = FRDeviceCollector()
    
    //  MARK: - Init
    
    /// Designated initialization method for HiddenValueCallback
    ///
    /// - Parameter json: JSON object of HiddenValueCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    required init(json: [String : Any]) throws {
        
        guard let outputs = json[CBConstants.output] as? [[String: Any]] else {
                throw AuthError.invalidCallbackResponse(String(describing: json))
        }
        
        for output in outputs {
            if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.location, let outputValue = output[CBConstants.value] as? Bool {
                locationRequired = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.metadata, let outputValue = output[CBConstants.value] as? Bool {
                metadataRequired = outputValue
            }
            else if let outputName = output[CBConstants.name] as? String, outputName == CBConstants.message, let outputValue = output[CBConstants.value] as? String {
                message = outputValue
            }
        }
        
        try super.init(json: json)
        
        prepareCollectors()
        
        type = CallbackType.DeviceProfileCallback.rawValue
    }
    
    
    func prepareCollectors() {
        if locationRequired {
            for deviceCollector in FRDeviceCollector.shared.collectors {
                if String(describing: deviceCollector).contains("FRProximity.LocationCollector") {
                    self.locationCollector = deviceCollector
                }
            }
            
            if let locationCollector = self.locationCollector {
                collector.collectors.append(locationCollector)
            }
            else {
                FRLog.w("LocationCollector is not found while constructing DeviceProfileCallback")
            }
        }
        
        if metadataRequired {
            for deviceCollector in FRDeviceCollector.shared.collectors {
                if String(describing: deviceCollector).contains("FRProximity.BluetoothCollector") {
                    self.profileCollector.collectors.append(deviceCollector)
                }
            }
            collector.collectors.append(self.profileCollector)
        }
    }
    
    
    /// Executes list of DeviceCollector to collect device information based on DeviceProfileCallback's attributes
    /// - Parameter completion: Completion block that returns JSON of collected information
    public func execute(_ completion: @escaping JSONCompletionCallback) {
        
        collector.collect { (json) in
            self._value = self.JSONStringify(value: json as AnyObject)
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
