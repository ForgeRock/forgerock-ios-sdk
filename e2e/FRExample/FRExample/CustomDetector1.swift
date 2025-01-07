//
//  CustomDetector1.swift
//  FRExample
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

public class CustomDetector1: JailbreakDetector {
  
  public init() { }
  
  public func analyze() -> Double {
    Log.v("\(self) analyzing")
    
    
    if canAccessSandboxRestrictedFiles() {
      Log.w("Security Warning: \(self) is returning 1.0")
      return 1.0
    }
    
    return 0.0
  }
  
  func canAccessSandboxRestrictedFiles() -> Bool {
    let restrictedPaths = ["/var/root/", "/var/mobile/Library/Preferences"]
    for path in restrictedPaths {
      if FileManager.default.isReadableFile(atPath: path) {
        return true // Unauthorized access detected
      }
    }
    return false
  }
  
}

