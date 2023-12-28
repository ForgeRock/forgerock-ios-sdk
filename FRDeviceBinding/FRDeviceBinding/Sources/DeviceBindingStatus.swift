// 
//  DeviceBindingStatus.swift
//  FRDeviceBinding
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// Error Status enum for Device binding related operations
public enum DeviceBindingStatus: LocalizedError, Equatable {
    case timeout
    case abort
    case unsupported(errorMessage: String?)
    case clientNotRegistered
    case unAuthorize
    case invalidCustomClaims
}

struct BindingStatusConstants {
    static let abort = "Abort"
    static let timeout = "Timeout"
    static let unsupported = "Unsupported"
    static let clientNotRegistered = "ClientNotRegistered"
}


///Extention to add computed properties for DeviceBindingStatus
public extension DeviceBindingStatus {
    
    
    
    /// Client error string for DeviceBindingStatus
    var clientError: String {
        switch self {
        case .timeout:
            return BindingStatusConstants.timeout
        case .abort:
            return BindingStatusConstants.abort
        case .unsupported:
            return BindingStatusConstants.unsupported
        case .clientNotRegistered:
            return BindingStatusConstants.clientNotRegistered
        case .unAuthorize:
            return BindingStatusConstants.abort
        case .invalidCustomClaims:
            return BindingStatusConstants.abort
        }
    }
    
    
    /// Error message for DeviceBindingStatus
    var errorMessage: String {
        switch self {
        case .timeout:
            return "Authentication Timeout"
        case .abort:
            return "User Terminates the Authentication"
        case .unsupported(let errorMessage):
            return errorMessage ?? "Device not supported. Please verify the biometric or Pin settings"
        case .clientNotRegistered:
            return "PublicKey or PrivateKey Not found in Device"
        case .unAuthorize:
            return "Invalid Credentials"
        case .invalidCustomClaims:
            return "Invalid Custom Claims"
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
