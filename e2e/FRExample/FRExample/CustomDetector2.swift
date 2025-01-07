// 
//  CustomDetector2.swift
//  FRExample
//
//  Copyright (c) 2024 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRCore

public class CustomDetector2: JailbreakDetector {
  
  public init() { }
  
  public func analyze() -> Double {
    Log.v("\(self) analyzing")
    
    
    if JailbreakChecker.amIJailbroken() {
      Log.w("Security Warning: \(self) is returning 1.0")
      return 1.0
    }
    
    return 0.0
  }
  
}

