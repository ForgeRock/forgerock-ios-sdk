//
//  WAKLogger.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Original work Copyright © 2018 Lyo Kato. All rights reserved.
//  Modified work Copyright © 2021 ForgeRock, Inc.
//

import Foundation

class WAKLogger {
    static func debug(_ msg: String) {
        FRLog.v(msg, subModule: WebAuthn.module)
    }
}
