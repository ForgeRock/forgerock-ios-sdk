//
//  ContentView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth

struct ContentView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    @StateObject var contentViewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            StatusView()
                .task {
                    contentViewModel.startSDK(statusViewModel: statusViewModel)
                }
            if contentViewModel.sdkStarted {
                LoginView()
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StatusViewModel())
    }
}
