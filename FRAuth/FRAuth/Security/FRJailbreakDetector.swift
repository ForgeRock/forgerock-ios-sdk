//
//  JailbreakDetector.swift
//  FRAuth
//
//  Copyright (c) 2019-2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// FRJailbreakResult represents the result of JailbreakDetector
///
/// - simulator: the device is known to be simulator; returning rawValue of 0.0
/// - noDetectorsFound: no detectors are found in JailbreakDetector; returning rawValue of -1.0
/// - result: JailbreakDetector analyzed given detectors, and returning maximum rawValue of all given detectors within range of 0.0 to 1.0
//public enum FRJailbreakResult {
//    case simulator
//    case noDetectorsFound
//    case result(Double)
//}
//
//extension FRJailbreakResult {
//    public var rawValue: Double {
//        switch self {
//        case .noDetectorsFound:
//            return -1.0
//        case .simulator:
//            return 0.0
//        case .result(let result):
//            return result
//        }
//    }
//}

/// JailbreakDetector is responsible to analyze and provide possibilities in score whether the device is suspicious for Jailbreak or not
@objc
public class FRJailbreakDetector: NSObject {
    
    /// Singleton instance of JailbreakDetector
    @objc
    public static let shared = FRJailbreakDetector()
    
    /// An array of JailbreakDetector to be analyzed
    @objc
    public var detectors: [JailbreakDetector]
    
    /// Private initialization method which initializes default array of JailbreakDetector
    @objc
    public override init() {
        detectors = [CydiaDetector(),
                     CydiaSubstrateDetector(),
                     SSHDetector(),
                     BashDetector(),
                     AptDetector(),
                     PrivateFileWritableDetector(),
                     SymbolicLinkDetector(),
                     DyldDetector(),
                     SandboxDetector()]
    }
    
    /// Analyzes and returns the result of given JailbreakDetector
    ///
    /// - NOTE: Any detector returns the result value less than 0.0 or greater than 1.0 will be rounded to a range of 0.0 to 1.0.
    ///
    /// - Returns: returns result of analysis of all given detectors
    @objc
    public func analyze() -> Double {
        #if targetEnvironment(simulator)
            FRLog.i("Currently running on Simulator; aborting JailbreakDetector")
            return 0.0
        #else
        if self.detectors.count > 0 {
            let _ = self.detectors.count
            var maxResult = 0.0
            var result = 0.0
            for detector in self.detectors {
                var detectorResult = detector.analyze()
                if detectorResult > 1.0 {
                    detectorResult = 1.0
                }
                else if detectorResult < 0 {
                    detectorResult = 0
                }
                
                maxResult = max(maxResult, detectorResult)
                result += detectorResult
            }
            
            return maxResult
        }
        else {
            FRLog.w("No JailbreakDetector is found")
            return -1.0
        }
        #endif
    }
}
