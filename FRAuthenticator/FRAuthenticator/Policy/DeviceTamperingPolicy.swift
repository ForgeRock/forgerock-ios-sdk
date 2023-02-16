// 
//  DeviceTamperingPolicy.swift
//  FRAuthenticator
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

/// The Device Tampering policy checks the integrity of device's software and hardware. It uses the `FRJailbreakDectector` available in the `FRCore` framework. The class analyzes the device by using multiple device tamper detectors and returns the highest score in the range between 0.0 to 1.0 from all the detectors, indicating how likely the device is Jailbroken: 0.0 - not likely, 0.5 - likely, 1.0 -very likely.
///
/// The policy receives the `score` value as parameter to use as reference on determine if the device is tampered. If the parameter is not passed, the policy will use the `defaultThresholdScore`.
///
/// JSON Policy format:
/// {"deviceTampering": {"score": 0.8}}
public class DeviceTamperingPolicy: FRAPolicy {
    
    public static let defaultThresholdScore : Double = 1.0
    
    public var name: String = "deviceTampering"
    
    /// The data used for policy validation.
    public var data: Any?
    
    public func evaluate() -> Bool {
        // Check if device is jailbroken
        let jailbreakScore = FRJailbreakDetector.shared.analyze()
        
        // Parse policy data
        if let jsonData = self.data as? Dictionary<String, AnyObject>, let thresholdScore = jsonData["score"] as? Double {
            // Compare the score threshold from the policy with the result from JailbreakDetector
            return compareResult(jailbreakScore: jailbreakScore, thresholdScore: thresholdScore)
        } else {
            // 'score' data not available, using 'defaultThresholdScore' to compare
            return compareResult(jailbreakScore: jailbreakScore, thresholdScore: DeviceTamperingPolicy.defaultThresholdScore)
        }
    }
    
    private func compareResult(jailbreakScore: Double, thresholdScore: Double) -> Bool{
        if jailbreakScore >= thresholdScore {
            FRALog.v("Device Tampering Policy fail: (jailbreak score: \(jailbreakScore)) (threshold score: \(thresholdScore))")
            return false
        } else {
            FRALog.v("Device Tampering Policy passed: (jailbreak score: \(jailbreakScore)) (threshold score: \(thresholdScore))")
            return true
        }
    }
    
}
