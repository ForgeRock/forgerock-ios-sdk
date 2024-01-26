//
//  PIProtect.swift
//  PingProtect
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth
import PingOneSignals

/*
 PIProtect is for initializing and interacting with Ping Protect SDK
 */
public final class PIProtect: NSObject {
    
    
    /// Inititialize Ping Protect SDK
    /// - Parameters:
    ///   - initParams: `PIInitParams` containing parameters for the init
    ///   - callback: Result callback of the init
    public static func initSDK(initParams: PIInitParams? = nil, callback: @escaping (Error?) -> Void) {
        
        let signalsInitParams = initParams != nil ? initParams!.getPOInitParams() : POInitParams()
        let pingOneSignals = PingOneSignals.initSDK(initParams: signalsInitParams)
        pingOneSignals.setInitCallback(callback)
    }
    
    /// Pause behavioral data collection
    public static func pauseBehavioralData() {
        PingOneSignals.sharedInstance()?.pauseBehavioralData()
    }
    
    /// Resume behavioral data collection
    public static func resumeBehavioralData() {
        PingOneSignals.sharedInstance()?.resumeBehavioralData()
    }
    
    /// Get signals data
    /// - Parameter callback: Callback containing ether the signals or an error
    internal static func getData(callback: @escaping (String?, Error?) -> Void) {
        guard let sharedInstace = PingOneSignals.sharedInstance() else {
            callback(nil, NSError(domain: "com.forgerock.ios.PingProtect", code: 1, userInfo: [NSLocalizedDescriptionKey: "SDK is not initialized"]))
            return
        }
        PingOneSignals.sharedInstance()?.getData(callback)
    }
    
}

/// Extension that contains a method for registering the callbacks
extension PIProtect {
    /// Register ``PingOneProtectInitializeCallback`` and ``PingOneProtectEvaluationCallback`` callbacks
    @objc static public func registerCallbacks() {
        CallbackFactory.shared.registerCallback(callbackType: "PingOneProtectInitializeCallback", callbackClass: PingOneProtectInitializeCallback.self)
        CallbackFactory.shared.registerCallback(callbackType: "PingOneProtectEvaluationCallback", callbackClass: PingOneProtectEvaluationCallback.self)
    }
}

