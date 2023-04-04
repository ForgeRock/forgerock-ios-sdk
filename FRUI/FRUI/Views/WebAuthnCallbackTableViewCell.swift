// 
//  WebAuthnCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import FRAuth

class WebAuthnCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {
    public static let cellIdentifier = "WebAuthnCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 180.0
    var callback: WebAuthnCallback?
    
    @IBOutlet weak var loadingView: FRLoadingView?
    @IBOutlet weak var messageLabel: UILabel?
    public var delegate: AuthStepProtocol?
    var viewController: UIViewController?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageLabel?.textColor = FRUI.shared.primaryColor
    }
    
    
    func updateCellWithViewController(callback: Callback, node: Node) {
        self.loadingView?.startLoading()
        
        if let webAuthnRegistration = callback as? WebAuthnRegistrationCallback {
            self.messageLabel?.text = "WebAuthn Registration Process"
            webAuthnRegistration.delegate = self
            webAuthnRegistration.register(node: node, onSuccess: { (attestation) in
                DispatchQueue.main.async {
                    self.delegate?.submitNode()
                }
            }) { (error) in
                DispatchQueue.main.async {
                    self.delegate?.submitNode()
                }
                FRLog.e(error.localizedDescription)
            }
        }
        else if let webAuthnAuthentication = callback as? WebAuthnAuthenticationCallback {
            self.messageLabel?.text = "WebAuthn Authentication Process"
            webAuthnAuthentication.delegate = self
            webAuthnAuthentication.authenticate(node: node, onSuccess: { (assertion) in
                DispatchQueue.main.async {
                    self.delegate?.submitNode()
                }
            }) { (error) in
                DispatchQueue.main.async {
                    self.delegate?.submitNode()
                }
                FRLog.e(error.localizedDescription)
            }
        }
    }
    
    func updateCellData(callback: Callback) {
    }
}


extension WebAuthnCallbackTableViewCell: PlatformAuthenticatorRegistrationDelegate {
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Exclude Credentials", message: nil, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                consentCallback(.reject)
            })
            let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
                consentCallback(.allow)
            }
            alert.addAction(cancelAction)
            alert.addAction(allowAction)

            guard let vc = self.viewController else {
                return
            }

            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Create Credentials", message: "KeyName: \(keyName) | rpName: \(rpName) | userName: \(userName)", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                consentCallback(.reject)
            })
            let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
                consentCallback(.allow)
            }
            alert.addAction(cancelAction)
            alert.addAction(allowAction)

            guard let vc = self.viewController else {
                return
            }

            vc.present(alert, animated: true, completion: nil)
        }
    }
}


extension WebAuthnCallbackTableViewCell: PlatformAuthenticatorAuthenticationDelegate {
    func localKeyExistsAndPasskeysAreAvailable() { }
    
    func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback) {
        
        let actionSheet = UIAlertController(title: "Select Credentials", message: nil, preferredStyle: .actionSheet)
        
        for keyName in keyNames {
            actionSheet.addAction(UIAlertAction(title: keyName, style: .default, handler: { (action) in
                selectionCallback(keyName)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            selectionCallback(nil)
        }))
        
        guard let vc = self.viewController else {
            return
        }
        
        if actionSheet.popoverPresentationController != nil {
            actionSheet.popoverPresentationController?.sourceView = self
            actionSheet.popoverPresentationController?.sourceRect = self.bounds
        }
        
        DispatchQueue.main.async {
            vc.present(actionSheet, animated: true, completion: nil)
        }
    }
}
