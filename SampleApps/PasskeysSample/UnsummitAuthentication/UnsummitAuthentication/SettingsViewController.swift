//
//  SettingsViewController.swift
//  UnsummitAuthentication
//
//  Created by George Bafaloukas on 24/07/2023.
//

import UIKit
import FRAuth
import JGProgressHUD

class SettingsViewController: UIViewController {

    @IBOutlet weak var faceIDSwitch: UISwitch!
    private var currentNode: Node?
    private let hud = JGProgressHUD()
    
    override func viewDidLoad() {
        PebbleBankUtilities.registerRequestInterceptors()
        self.faceIDSwitch.isOn = UserDefaults.standard.object(forKey: PebbleBankUtilities.biometricsEnabledKey) as? Bool ?? false
    }
    
    @IBAction func changeFaceIDAction(_ sender: UISwitch) {
        if sender.isOn {
            FRSession.authenticate(authIndexValue: PebbleBankUtilities.biometricsRegistrationJourney) { result, node, error in
                self.handleNodes(token: result, node: node, error: error)
            }
        } else {
            UserDefaults.standard.set(nil, forKey: PebbleBankUtilities.biometricsEnabledKey)
        }
    }
    
    // MARK: - Private Methods
    
    func handleNodes(token: Token?, node: Node?, error: Error?) {
        if let _ = token {
            FRUser.currentUser?.getAccessToken(completion: { user, error in
                if error != nil {
                    print("User unable to get AccessToken with error: \(String(describing: error?.localizedDescription))")
                    FRUser.currentUser?.logout()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.hud.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                        return
                    }
                }
                DispatchQueue.main.async {
                    UserDefaults.standard.set(self.faceIDSwitch.isOn, forKey: PebbleBankUtilities.biometricsEnabledKey)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.hud.dismiss(animated: true)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            })
        } else if let node = node {
            self.currentNode = node
            for callback in node.callbacks {
                if let passwordCallback = callback as? PasswordCallback {
                    let alert = UIAlertController(title: "Verify account", message: "Please enter your Password", preferredStyle: .alert)
                    
                    DispatchQueue.main.async {
                        alert.addTextField { (textField) in
                            textField.placeholder = passwordCallback.prompt
                            textField.isSecureTextEntry = true
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        }
                        
                        if let textfields = alert.textFields, textfields.count > 0 {
                            let submitAction = UIAlertAction(title: "Next", style: .default) { (_) in
                                for (index, textField) in textfields.enumerated() {
                                    if let thisCallback = node.callbacks[index] as? SingleValueCallback {
                                        thisCallback.setValue(textField.text)
                                    }
                                }
                                node.next { (token: Token?, node, error) in
                                    self.handleNodes(token: token, node: node, error: error)
                                }
                            }
                            alert.addAction(submitAction)
                        }
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                if let registrationCallback = callback as? WebAuthnRegistrationCallback {
                    registrationCallback.delegate = self
                    DispatchQueue.main.async {
                        // Note that the `Node` parameter in `.register()` is an optional parameter.
                        // If the node is provided, the SDK automatically sets the error outcome or attestation to the designated HiddenValueCallback
                        registrationCallback.register(node: node, deviceName: UIDevice.current.name, usePasskeysIfAvailable: PebbleBankUtilities.usePasskeysIfAvailable) { (attestation) in
                            // Registration is successful
                            // Submit the Node using Node.next()
                            node.next { (token: Token?, node, error) in
                                DispatchQueue.main.async {
                                    self.hud.textLabel.text = "Registering"
                                    self.hud.show(in: self.view)
                                }
                                self.handleNodes(token: token, node: node, error: error)
                            }
                        } onError: { (error) in
                            // An error occurred during the registration process
                            // Submit the Node using Node.next()
                            let alert = UIAlertController(title: "WebAuthnError", message: "Something went wrong registering the device", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                node.next { (token: Token?, node, error) in
                                    self.handleNodes(token: token, node: node, error: error)
                                }
                            })
                            alert.addAction(okAction)
                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        } else {
            print("Something went wrong with error: \(String(describing: error?.localizedDescription))")
            FRUser.currentUser?.logout()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.hud.dismiss(animated: true)
                self.navigationController?.popToRootViewController(animated: true)
                return
            }
        }
    }
}

extension SettingsViewController: PlatformAuthenticatorRegistrationDelegate {
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {}
    
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {}
}
