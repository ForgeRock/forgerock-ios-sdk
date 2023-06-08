//
//  UserInfoViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@MainActor class UserInfoViewModel: ObservableObject {
    @Published private(set) var description: String = ""
    
    var statusViewModel: StatusViewModel?
    
    func loadUserInfo() {
        guard let currentUser = FRUser.currentUser else {
            description = "No logged in User\nPlease Log in"
            return
        }
        currentUser.getUserInfo(completion: { userInfo, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.statusViewModel?.status = Status(statusDescription: error.localizedDescription, statusType: .error)
                } else if let userInfo = userInfo {
                    var desc = ""
                    if let name = userInfo.name {
                        desc += "Name: " + name
                    }
                    if let preferredUsername = userInfo.preferredUsername {
                        desc += "\nPreferred Username: " + preferredUsername
                    }
                    if let sub = userInfo.sub {
                        desc += "\nSub: " + sub
                    }
                    if let email = userInfo.email {
                        desc += "\nEmail: " + email
                    }
                    if let phoneNumber = userInfo.phoneNumber {
                        desc += "\nPhone Number: " + phoneNumber
                    }
                    if let birthDate = userInfo.birthDate {
                        desc += "\nBirth Date: " + String(describing: birthDate)
                    }
                    self.description = desc
                }
            }
        })
    }
}
