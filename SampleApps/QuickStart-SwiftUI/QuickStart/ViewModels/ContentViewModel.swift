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
        
        do {
            // By default the SDK uses FRAuthConfig.plist file for the configuration.
            // You can also specify the desired config file like this: `FRAuth.configPlistFileName = "DesiredFRAuthConfig"`
            // You can also specify the configurations dynamically by using FROptions. Please see the docs for more details here: https://backstage.forgerock.com/docs/sdks/latest/ios/configuring/dynamic-configuration.html
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
