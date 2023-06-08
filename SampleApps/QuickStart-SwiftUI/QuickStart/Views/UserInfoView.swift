//
//  UserInfoView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth

struct UserInfoView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    @StateObject var userInfoViewModel: UserInfoViewModel = UserInfoViewModel()
    
    var body: some View {
        Text("Logged in User")
            .font(.title)
            .padding()
        Text(userInfoViewModel.description)
            .multilineTextAlignment(.center)
            .onAppear {
                userInfoViewModel.statusViewModel = statusViewModel
                userInfoViewModel.loadUserInfo()
            }
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView()
    }
}
