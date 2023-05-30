//
//  NodeViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@MainActor class NodeViewModel: ObservableObject {
    @Published var callbackViewModels = [CallbackViewModel]()
    @Published var showNodeView = false
    @Published var shouldDismiss: Bool = false
    
    var statusViewModel: StatusViewModel?
    var journeyName: String = "\(FRAuth.shared?.options?.authServiceName ?? "") Journey" 
    var node: Node?
    
    init(node: Node? = nil) {
        self.node = node
    }
    
    func parseNode() {
        guard let node = node else {
            print("Node is missing")
            return
        }
        
        for callback in node.callbacks {
            if let nameCallBack = callback as? NameCallback {
                callbackViewModels.append(CallbackViewModel(name: nameCallBack.prompt!, value: ""))
            } else if let passwordCallback = callback as? PasswordCallback {
                callbackViewModels.append(CallbackViewModel(name: passwordCallback.prompt!, value: "", isSecret: true))
            } else {
                statusViewModel?.status = Status(statusDescription: "\(callback.type) is not suppoorted", statusType: .error)
                callbackViewModels.removeAll()
            }
        }
        
        if callbackViewModels.count > 0 {
            statusViewModel?.status = Status(statusDescription: "Node successfully parsed", statusType: .info)
        }
        
    }
    
    func submitNode() {
        guard let node = node else { return }
        
        for (index, input) in callbackViewModels.enumerated() {
            if let callback =  node.callbacks[index] as? SingleValueCallback {
                callback.setValue(input.value)
            }
        }
        
        node.next { [weak self] (user: FRUser?, node, error) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.statusViewModel?.status = Status(statusDescription: error.localizedDescription, statusType: .error)
                } else if user != nil {
                    self.statusViewModel?.status = Status(statusDescription: "Login Success", statusType: .success)
                    self.statusViewModel?.isLoggedIn = true
                    self.shouldDismiss = true
                } else if let node = node {
                    self.node = node
                    self.showNodeView = true
                }
            }
        }
    }
}
