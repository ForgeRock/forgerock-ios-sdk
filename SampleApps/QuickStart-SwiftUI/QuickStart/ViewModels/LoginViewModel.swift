//
//  LoginViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@MainActor class LoginViewModel: ObservableObject {
    @Published var showNodeView = false
    
    var statusViewModel: StatusViewModel?
    var node: Node?
    
    func checkForLoggedInUser() {
        if FRUser.currentUser != nil {
            statusViewModel?.isLoggedIn = true
            statusViewModel?.status = Status(statusDescription: "Logged in user detected", statusType: .info)
        } else {
            statusViewModel?.isLoggedIn = false
            statusViewModel?.status = Status(statusDescription: "No logged in user detected", statusType: .info)
        }
    }
    
    func login() {
        if FRUser.currentUser == nil {
            FRUser.login() { [weak self] user, node, error in
                guard let self = self else { return }
                if error != nil {
                    print(error.debugDescription)
                    self.statusViewModel?.status = Status(statusDescription: "Authentication Error", statusType: .error)
                } else if user != nil {
                    self.statusViewModel?.status = Status(statusDescription: "Login Success", statusType: .success)
                    self.statusViewModel?.isLoggedIn = true
                } else if let node = node {
                    self.node = node
                    DispatchQueue.main.async {
                        self.showNodeView = true
                        self.statusViewModel?.status = Status(statusDescription: "Journey started", statusType: .info)
                    }
                }
            }
        } else {
            FRUser.currentUser?.logout()
            statusViewModel?.isLoggedIn = false
            statusViewModel?.status = Status(statusDescription: "Logged out", statusType: .info)
        }
    }
}
