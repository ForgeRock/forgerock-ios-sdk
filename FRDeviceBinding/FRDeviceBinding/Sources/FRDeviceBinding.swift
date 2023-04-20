//
//  FRDeviceBinding.swift
//  FRDeviceBinding
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@objc public final class FRDeviceBinding: NSObject  {
    
    /// Register ``DeviceBindingCallback`` and ``DeviceSigningVerifierCallback`` callbacks
    @objc static public func registerCallbacks() {
        CallbackFactory.shared.registerCallback(callbackType: "DeviceBindingCallback", callbackClass: DeviceBindingCallback.self)
        CallbackFactory.shared.registerCallback(callbackType: "DeviceSigningVerifierCallback", callbackClass: DeviceSigningVerifierCallback.self)
    }
}
