// 
//  PinCollector.swift
//  FRDeviceBinding
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit


/// Protocol for collecting the Pin
public protocol PinCollector: AnyObject {
    /// Delegate method to collect the Pin
    /// - Parameter prompt: Prompt to be shown during the pin collection
    /// - Parameter completion: callback containing the Pin
    func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void)
}


/// Default implementation for PinCollector protocol
public class DefaultPinCollector: NSObject, PinCollector {
    
    var alert: UIAlertController!
    
    public func collectPin(prompt: Prompt, completion: @escaping (String?) -> Void) {
        
        DispatchQueue.main.async {
            
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            var topVC = keyWindow?.rootViewController
            while let presentedViewController = topVC?.presentedViewController {
                topVC = presentedViewController
            }
            guard let topVC = topVC else {
                completion(nil)
                return
            }
            
            self.alert =  UIAlertController(title: prompt.title, message: prompt.description, preferredStyle: .alert)
            self.alert.addTextField { textField in
                textField.keyboardType = .numberPad
                textField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControl.Event.editingChanged)
            }
            
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok button title"), style: .default) { [weak self] (_) in
                completion(self?.alert.textFields?.first?.text)
            }
            okAction.isEnabled = false
            self.alert.addAction(okAction)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Ok button title"), style: .cancel, handler: { (_) in
                completion(nil)
            })
            self.alert.addAction(cancelAction)
            
            topVC.present(self.alert, animated: true, completion: nil)
        }
    }
    
    
    // Disable Ok button if textfield is empty
    @objc func textFieldDidChange(_ sender: UITextField) {
        alert?.actions.first?.isEnabled = sender.text!.count > 0
    }
    
}
