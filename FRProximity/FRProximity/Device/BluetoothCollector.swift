//
//  BluetoothCollector.swift
//  FRProximity
//
//  Copyright (c) 2019-2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import CoreBluetooth
import FRAuth

/// BluetoothCollector is responsible for collecting BLE information of the device using CBPeripheralManager.
public class BluetoothCollector: DeviceCollector {
    
    /// Name of current collector
    public var name: String = "bluetooth"
    /// CBPeripheralManager to validate if the device can turn on BLE
    var manager = CBPeripheralManager()
    /// BluetoothManagerDelegation class for implementing CBPeripheralManagerDelegate protocols
    var managerDelegate = BluetoothManagerDelegation()
    
    /// Collects BLE information using CBPeripheralManager
    ///
    /// - Parameter completion: completion block
    public func collect(completion: @escaping DeviceCollectorCallback) {
        if self.manager.state == .unknown {
            self.managerDelegate.completionCallback = completion
            self.manager.delegate = self.managerDelegate
            self.manager.startAdvertising(nil)
        }
        else {
            let isBLESupported = self.manager.state != .unsupported && self.manager.state != .unknown && self.manager.state != .unauthorized
            var result: [String: Any] = [:]
            result["supported"] = isBLESupported
            completion(result)
        }
    }
}

/// BluetoothManagerDelegation class is responsible to implement CBPeripheralManagerDelegate protocols
class BluetoothManagerDelegation: NSObject, CBPeripheralManagerDelegate {
    
    var completionCallback: DeviceCollectorCallback?
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let isBLESupported = peripheral.state != .unsupported && peripheral.state != .unknown && peripheral.state != .unauthorized
        var result: [String: Any] = [:]
        result["supported"] = isBLESupported
        if let completion = self.completionCallback {
            completion(result)
        }
        peripheral.stopAdvertising()
    }
}
