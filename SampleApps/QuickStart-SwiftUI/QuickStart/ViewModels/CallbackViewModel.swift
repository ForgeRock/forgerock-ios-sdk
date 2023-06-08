//
//  CallbackViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation

class CallbackViewModel {
    var name: String
    var value: String
    var isSecret: Bool
    
    init(name: String, value: String, isSecret: Bool = false) {
        self.name = name
        self.value = value
        self.isSecret = isSecret
    }
}

extension CallbackViewModel: Identifiable, Hashable {
    var identifier: String {
        return UUID().uuidString
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(identifier)
    }
    
    public static func == (lhs: CallbackViewModel, rhs: CallbackViewModel) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
