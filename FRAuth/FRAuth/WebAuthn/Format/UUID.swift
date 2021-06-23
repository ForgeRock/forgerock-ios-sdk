//
//  UUID.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation

internal class UUIDHelper {

    static let zero = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    static let zeroBytes: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    static func toBytes(_ uuid: UUID) -> [UInt8] {
        return [
            uuid.uuid.0,
            uuid.uuid.1,
            uuid.uuid.2,
            uuid.uuid.3,
            uuid.uuid.4,
            uuid.uuid.5,
            uuid.uuid.6,
            uuid.uuid.7,
            uuid.uuid.8,
            uuid.uuid.9,
            uuid.uuid.10,
            uuid.uuid.11,
            uuid.uuid.12,
            uuid.uuid.13,
            uuid.uuid.14,
            uuid.uuid.15
        ]

    }
}
