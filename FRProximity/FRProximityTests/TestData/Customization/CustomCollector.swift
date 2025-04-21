// 
//  CustomCollector.swift
//  FRProximityTests
//
//  Copyright (c) 2020 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import FRAuth

class CustomCollector: DeviceCollector {
    var name: String = "metadata"
    func collect(completion: @escaping DeviceCollectorCallback) {
        var customdata: [String: Any] = [:]
        customdata["custom"] = ["key1": "value1", "key2": false, "key3": 123]
        completion(customdata)
    }
}
