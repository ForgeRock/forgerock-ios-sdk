//
//  PingOneProtectEvaluationCallback.swift
//  PingProtect
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth


/**
 * Callback to evaluate Ping One Protect
 */
open class PingOneProtectEvaluationCallback: ProtectCallback {
    
    /// The pauseBehavioralData received from server
    public private(set) var pauseBehavioralData: Bool = Bool()
    
    /// Signals input key in callback response
    private var signalsKey: String = String()
    
    
    /// Designated initialization method for PingOneProtectEvaluationCallback
    ///
    /// - Parameter json: JSON object of PingOneProtectEvaluationCallback
    /// - Throws: AuthError.invalidCallbackResponse for invalid callback response
    public required init(json: [String : Any]) throws {

        try super.init(json: json)
        
        guard let pauseBehavioralData = self.outputValues[CBConstants.pauseBehavioralData] as? Bool else {
            throw AuthError.invalidCallbackResponse("Missing pauseBehavioralData")
        }
        self.pauseBehavioralData = pauseBehavioralData
        
        if !self.derivedCallback {
            guard let signalsKey = self.inputNames.filter({ $0.contains(CBConstants.signals) }).first else {
                throw AuthError.invalidCallbackResponse("Missing signalsKey")
            }
            self.signalsKey = signalsKey
        }
    }
    
    
    /// Get Signals data from the device
    /// - Parameter completion: Completion block for signals result
    open func getData(completion: @escaping ProtectResultCallback) {
        
        PIProtect.getData { data, error in
            if let data = data {
                self.setSignals(data)
                // Pause behavioral data collection if `pauseBehavioralData` is set to FALSE on the server node
                if self.pauseBehavioralData {
                    PIProtect.pauseBehavioralData()
                }
                completion(.success)
            } else if let error = error as? NSError {
                self.setClientError(error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    
    /// Sets `signals` value in callback response
    /// - Parameter signals: String value of `signals`]
    public func setSignals(_ signals: String) {
        if derivedCallback {
            self.setSignalsInHiddenCallback(value: signals)
        } else {
            self.inputValues[self.signalsKey] = signals
        }
    }
    
    
    /// Sets `signals` value  to the `HiddenValueCallback` which is associated with the ProtectCallback
    /// - Parameter signals: String value of `signals`]
    func setSignalsInHiddenCallback(value: String) {
        if let node = self.node {
            for callback in node.callbacks {
                if let hiddenCallback = callback as? HiddenValueCallback {
                    if let callbackId = hiddenCallback.id, callbackId.contains(CBConstants.riskEvaluationSignals) {
                        hiddenCallback.setValue(value)
                        return
                    }
                }
            }
        }
        FRLog.e("Failed to set signals to HiddenValueCallback; HiddenValueCallback with \(CBConstants.riskEvaluationSignals) is missing")
    }
}


/// Definition for completion of Protect callback methods
public typealias ProtectResultCallback = (_ result: ProtectResult) -> Void


/// Result enum for Protect
public enum ProtectResult {
    case success
    case failure(NSError)
}

