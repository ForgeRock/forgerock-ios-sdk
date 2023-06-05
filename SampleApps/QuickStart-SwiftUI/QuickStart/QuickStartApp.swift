//
//  QuickStartApp.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI

@main
struct QuickStartApp: App {
    @StateObject private var statusViewModel = StatusViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(statusViewModel)
        }
    }
}
