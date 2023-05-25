//
//  Status.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation

struct Status {
    var statusDescription: String
    var statusType: StatusType
}

enum StatusType {
    case error
    case info
    case success
    case none
}
