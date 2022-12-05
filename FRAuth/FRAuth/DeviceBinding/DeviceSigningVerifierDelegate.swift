// 
//  DeviceSigningVerifierDelegate.swift
//  FRAuth
//
//  Copyright (c) 2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

public protocol DeviceSigningVerifierDelegate: AnyObject {
    /// Delegate method to choose from multiple keys
    func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping DeviceSigningVerifierKeySelectionCallback)
}

extension DeviceSigningVerifierDelegate {
    
    /// Default implementation with a simple action sheet UI
    public func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping DeviceSigningVerifierKeySelectionCallback) {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        var topVC = keyWindow?.rootViewController
        while let presentedViewController = topVC?.presentedViewController {
            topVC = presentedViewController
        }
        guard let topVC = topVC else { return }
        
        let actionSheet = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
        
        for userKey in userKeys {
            actionSheet.addAction(UIAlertAction(title: userKey.userName, style: .default, handler: { (action) in
                selectionCallback(userKey)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            selectionCallback(nil)
        }))
        
        if actionSheet.popoverPresentationController != nil {
            actionSheet.popoverPresentationController?.sourceView = topVC.view
            actionSheet.popoverPresentationController?.sourceRect = topVC.view.bounds
        }
        
        DispatchQueue.main.async {
            topVC.present(actionSheet, animated: true, completion: nil)
        }
    }
}


/// Completion Callback for key selection for WebAuthn registration/authentication operations
public typealias DeviceSigningVerifierKeySelectionCallback = (_ selectedUserKey: UserKey?) -> Void
