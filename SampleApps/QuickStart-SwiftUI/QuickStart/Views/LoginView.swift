//
//  LoginView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth

struct LoginView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    var body: some View {
        VStack {
            NavigationStack {
                VStack {
                    if statusViewModel.isLoggedIn {
                        UserInfoView()
                    } else {
                        Text("Please Log in")
                            .font(.title)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(statusViewModel.isLoggedIn ? "Logout" : "Login") {
                        loginViewModel.login()
                    }
                    .foregroundColor(.white)
                    .font(Font.body.bold())
                    .padding(10)
                    .padding(.horizontal, 20)
                    .background(statusViewModel.isLoggedIn ? .red : .green)
                    .cornerRadius(10)
                }
                .padding()
                
                .navigationBarTitle("ForgeRock SDK", displayMode: .inline)
                .navigationDestination(isPresented: $loginViewModel.showNodeView) {
                    NodeView(nodeViewModel: NodeViewModel(node: loginViewModel.node))
                }
            }
            .task {
                loginViewModel.statusViewModel = statusViewModel
                loginViewModel.checkForLoggedInUser()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(StatusViewModel())
    }
}
