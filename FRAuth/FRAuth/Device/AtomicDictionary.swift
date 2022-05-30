// 
//  AtomicStorage.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation

class AtomicDictionary {
    
    let isolationQueue: DispatchQueue = DispatchQueue(label: "com.forgerock.serialqueue")
    
    var result: [String: Any] = [:]
    
   
    func set(key: String, value: [String: Any]) {
        isolationQueue.sync { [weak self] in
            if value.keys.count > 0 {
                self?.result[key] = value
            }
        }
    }
    
    func get() -> [String: Any] {
        isolationQueue.sync { [weak self] in
            return self?.result ?? [:]
        }
    }
}

