// 
//  UserKeySelector.swift
//  FRAuth
//
//  Copyright (c) 2022-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

/// Protocol for selecting ``UserKey``
public protocol UserKeySelector: AnyObject {
    /// Method to choose from multiple keys
    /// - Parameter userKeys: List of ``UserKey``s
    /// - Parameter selectionCallback: ``UserKey`` selection callback
    func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping UserKeySelectorCallback)
}

/// Default implementation for UserKeySelector protocol
public class DefaultUserKeySelector: NSObject, UserKeySelector {
    
    /// Default implementation with a simple action sheet UI
    public func selectUserKey(userKeys: [UserKey], selectionCallback: @escaping UserKeySelectorCallback) {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            var topVC = keyWindow?.rootViewController
            while let presentedViewController = topVC?.presentedViewController {
                topVC = presentedViewController
            }
            guard let topVC = topVC else { return }
            
            let actionSheet = UIAlertController(title: NSLocalizedString("Select User", comment: "User selection list title"), message: nil, preferredStyle: UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet)
            
            for userKey in userKeys {
                actionSheet.addAction(UIAlertAction(title: userKey.userName, style: .default, handler: { (action) in
                    selectionCallback(userKey)
                }))
            }
            
            actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .cancel, handler: { (action) in
                selectionCallback(nil)
            }))
            
            if actionSheet.popoverPresentationController != nil {
                actionSheet.popoverPresentationController?.sourceView = topVC.view
                actionSheet.popoverPresentationController?.sourceRect = topVC.view.bounds
            }
            
            topVC.present(actionSheet, animated: true, completion: nil)
        }
    }
}


/// Completion Callback for selected user key
public typealias UserKeySelectorCallback = (_ selectedUserKey: UserKey?) -> Void
