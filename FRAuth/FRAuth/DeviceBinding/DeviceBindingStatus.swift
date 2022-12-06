// 
//  DeviceBindingStatus.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// Error Status enum for Device binding related operations
public enum DeviceBindingStatus: LocalizedError {
    case timeout
    case abort
    case unsupported(errorMessage: String?)
    case unRegister
}


///Extention to add computed properties for DeviceBindingStatus
public extension DeviceBindingStatus {
    
    /// Client error string for DeviceBindingStatus
    var clientError: String {
        switch self {
        case .timeout:
            return "Timeout"
        case .abort:
            return "Abort"
        case .unsupported:
            return "Unsupported"
        case .unRegister:
            return "Unsupported"
        }
    }
    
    
    /// Error message for DeviceBindingStatus
    var errorMessage: String {
        switch self {
        case .timeout:
            return "Biometric Timeout"
        case .abort:
            return "User Terminates the Authentication"
        case .unsupported(let errorMessage):
            return errorMessage ?? "Device not supported. Please verify the biometric or Pin settings"
        case .unRegister:
            return "PublicKey or PrivateKey Not found in Device"
        }
    }
}


/// Result enum for Device Binding
public enum DeviceBindingResult {
    case success
    case failure(DeviceBindingStatus)
}


/// Callback definition for completion of Device Binding
public typealias DeviceBindingResultCallback = (_ result: DeviceBindingResult) -> Void


/// Result enum for Device Signing
public enum DeviceSigningResult {
    case success
    case failure(DeviceBindingStatus)
}


/// Callback definition for completion of Device Signing
public typealias DeviceSigningResultCallback = (_ result: DeviceSigningResult) -> Void
