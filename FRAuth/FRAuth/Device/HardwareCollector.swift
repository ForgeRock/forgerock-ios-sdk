//
//  HardwareCollector.swift
//  FRAuth
//
//  Copyright (c) 2019-2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import AVFoundation
import UIKit

/// HardwareCollector is responsible for collecting hardware information of the device using ProcessInfo.
public class HardwareCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "hardware"
    
    /// Initializes HardwareCollector instance
    public init() { }
    
    /// Collects hardware information using ProcessInfo
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        var result: [String: Any] = [:]
        let pi = ProcessInfo.processInfo
        result["cpu"] = pi.processorCount
//        result["activeCPU"] = pi.activeProcessorCount
//        result["multitaskSupport"] = UIDevice.current.isMultitaskingSupported
        result["manufacturer"] = "Apple"
        result["memory"] = Int(self.getMemorySize())
        result["display"] = self.getScreenInfo()
        result["camera"] = self.getCameraInfo()
        completion(result)
    }

    
    /// Retrieves current device's camera related information
    ///
    /// - Returns: Current device's camera information in Dictionary
    func getCameraInfo() -> [String: Any] {
        if #available(iOS 10.2, *) {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            return ["numberOfCameras": session.devices.count]
        }
        else {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            return ["numberOfCameras": session.devices.count]
        }
    }
    

    /// Retrieves current device's screen related information
    ///
    /// - Returns: Current device's screen information in Dictionary
    func getScreenInfo() -> [String: Any] {
        var result: [String: Any] = [:]
        result["width"] = Int(UIScreen.main.bounds.width)
        result["height"] = Int(UIScreen.main.bounds.height)
        result["orientation"] = UIDevice.current.orientation.isPortrait ? 1 : 0
        return result
    }
    
    
    /// Calculates current device's total memory size in MB
    ///
    /// - Returns: Current device's memory size in MB
    func getMemorySize() -> Double {
        let pi = ProcessInfo.processInfo
        var totalMemory: Double = 0.0;
        let physicalMem = Double(pi.physicalMemory)
        totalMemory = (physicalMem / 1024.00) / 1024.00
        return totalMemory
    }
}
