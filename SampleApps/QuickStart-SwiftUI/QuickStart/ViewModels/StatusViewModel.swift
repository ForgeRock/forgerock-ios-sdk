//
//  StatusViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import SwiftUI

@MainActor class StatusViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var status = Status(statusDescription: "", statusType: .info)
    
    var color: Color {
        switch status.statusType {
        case .error:
            return .red
        case .info:
            return .orange
        case .success:
            return .green
        case .none:
            return .white
        }
    }
}


