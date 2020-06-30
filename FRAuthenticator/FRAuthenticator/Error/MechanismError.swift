//
//  MechanismError.swift
//  FRAuthenticator
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore


/// MechanismError represents an error captured by FRAuthenticator SDK for any operations related to Mechanism class
///
/// - invalidQRCode: Fail to parse or validate given QR Code
/// - invalidType: Given QR Code does not have valid type
/// - missingInformation: Given QR Code does not contain necessary information to construct Mechanism object
/// - invalidInformation: Given QR Code contains some invalid information to construct Mechanism object
public enum MechanismError: FRError {
    case invalidQRCode
    case invalidType
    case missingInformation(String)
    case invalidInformation(String)
    case alreadyExists(String)
    case failedToUpdateInformation(String)
}


public extension MechanismError {
    
    /// Unique error code for given error
    var code: Int {
        return self.parseErrorCode()
    }
    
    /// Parses MechanismError value into integer error code
    ///
    /// - Returns: Int value of unique error code
    func parseErrorCode() -> Int {
        switch self {
        case .invalidQRCode:
            return 6000000
        case .invalidType:
            return 6000001
        case .missingInformation:
            return 6000002
        case .invalidInformation:
            return 6000003
        case .alreadyExists:
            return 6000004
        case .failedToUpdateInformation:
            return 6000005
        }
    }
}


// MARK: - CustomNSError protocols
extension MechanismError: CustomNSError {
    
    /// An error domain for MechanismError
    public static var errorDomain: String { return "com.forgerock.ios.frauthenticator.mechanism" }
    
    /// Error codes for each error enum
    public var errorCode: Int {
        return self.parseErrorCode()
    }
    
    /// Error UserInfo
    public var errorUserInfo: [String : Any] {
        switch self {
        case .invalidQRCode:
            return [NSLocalizedDescriptionKey: "Invalid QR Code given for Mechanism initialization"]
        case .invalidType:
            return [NSLocalizedDescriptionKey: "Invalid or missing auth type from given QR Code"]
        case .missingInformation(let param):
            return [NSLocalizedDescriptionKey: "Missing information: \(param)"]
        case .invalidInformation(let param):
            return [NSLocalizedDescriptionKey: "Invalid information: \(param)"]
        case .alreadyExists(let param):
            return [NSLocalizedDescriptionKey: "Given Mechanism already exsists: Mechanism.identifier (\(param))"]
        case .failedToUpdateInformation(let param):
            return [NSLocalizedDescriptionKey: "Failed to update current Mechanism object in StorageClient: (\(param))"]
        }
    }
}

