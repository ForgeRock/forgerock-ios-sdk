//
//  CallbackConstants.swift
//  FRAuth
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

// Reference: https://docs.oracle.com/javase/7/docs/api/javax/security/auth/callback/ConfirmationCallback.html

/// Option Type for Callback
///
/// - unspecifiedOption: unpsecifiedOption; -1
/// - yesNoOption: YES/NO option; 0
/// - yesNoCancelOption: YES/NO/CANCEL option; 1
/// - okCancelOption: OK/CANCEL option; 2
/// - unknown: default when value is not provided
@objc(FRCallbackOptionType)
public enum OptionType: Int {
    
    case unspecifiedOption = -1
    case yesNoOption = 0
    case yesNoCancelOption = 1
    case okCancelOption = 2
    case unknown
}


/// Option for Callback
///
/// - yes: YES; 0
/// - no: NO; 1
/// - cancel: CANCEL; 2
/// - ok: OK; 3
/// - unknown: default when value is not provided
@objc(FRCallbackOption)
public enum Option: Int {
    case yes = 0
    case no = 1
    case cancel = 2
    case ok = 3
    case unknown
}


/// Message Type for Callback
///
/// - information: INFORMATION; 0
/// - warning: WARNING; 1
/// - error: ERROR; 2
/// - unknown: default when value is not provided
@objc(FRCallbackMessageType)
public enum MessageType: Int {
    case information = 0
    case warning = 1
    case error = 2
    case unknown
}
