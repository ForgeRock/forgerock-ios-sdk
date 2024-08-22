//
//  FRCaptchaEnterprise.swift
//  FRCaptchaEnterprise
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@objc public final class FRCaptchaEnterprise: NSObject  {
    
    /// Register ``CaptchaEnterpriseCallback`` callback
    @objc static public func registerCallbacks() {
        CallbackFactory.shared.registerCallback(callbackType: "ReCaptchaEnterpriseCallback", callbackClass: ReCaptchaEnterpriseCallback.self)
    }
    
}
