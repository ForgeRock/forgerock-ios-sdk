//
//  JSON.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation

class JSONHelper<T: Codable> {

    static func decode(_ json: String) -> Optional<T> {
        if let data: Data = json.data(using: .utf8) {
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch let error {
                WAKLogger.debug("<JSONHelper> failed to decode: \(error)")
                return nil
            }
        } else {
            WAKLogger.debug("<JSONHelper> invalid UTF-8 string")
            return nil
        }
    }

    static func encode(_ obj: T) -> Optional<String> {
        do {
            let data = try JSONEncoder().encode(obj)
            if let str = String(data: data, encoding: .utf8) {
                return str
            } else {
                WAKLogger.debug("<JSONHelper> invalid UTF-8 string")
                return nil
            }
        } catch let error {
            WAKLogger.debug("<JSONHelper> failed to encode: \(error)")
            return nil
        }
    }
}
