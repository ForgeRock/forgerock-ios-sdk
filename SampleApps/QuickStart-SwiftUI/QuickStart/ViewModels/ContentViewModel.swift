//
//  ContentViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@MainActor class ContentViewModel: ObservableObject {
    @Published private(set) var sdkStarted = false
    
    func startSDK(statusViewModel: StatusViewModel) {
        FRLog.setLogLevel([.network, .all])
        FRAuth.configPlistFileName = "FRAuthConfig"
        
        do {
            try FRAuth.start()
            print("SDK initialized successfully")
            statusViewModel.status = Status(statusDescription: "SDK ready", statusType: .success)
            sdkStarted = true
        } catch {
            print(error)
            statusViewModel.status = Status(statusDescription: error.localizedDescription, statusType: .error)
            sdkStarted = false
        }
    }
}
