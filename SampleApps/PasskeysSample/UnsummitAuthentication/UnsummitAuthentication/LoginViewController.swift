//
//  ViewController.swift
//  BioExample
//
//  Created by George Bafaloukas on 07/07/2021.
//

import UIKit
import FRAuth
import FRCore
import WebKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loginStackView: UIStackView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var step1StackView: UIStackView!
    @IBOutlet weak var step2StackView: UIStackView!
    @IBOutlet weak var step3StackView: UIStackView!
    @IBOutlet weak var step4StackView: UIStackView!
    
    private var currentNode: Node?
    private var textFieldArray = [UITextField]()
    private let hud = JGProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.statusLabel?.text = "Welcome to Pebble Bank"
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap) // Add gesture recognizer to background view
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        // START the FR SDK
        do {
            try FRAuth.start(options: PebbleBankUtilities.frCongiguration())
            print("SDK initialized successfully")
            FRLog.setLogLevel([.error, .network])
            
        }
        catch {
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.step1StackView.alpha = 0.0
        self.step2StackView.alpha = 0.0
        self.step3StackView.alpha = 0.0
        self.step4StackView.alpha = 0.0
        
        self.updateStatus()
        self.hud.textLabel.text = "Loading"
        self.hud.show(in: self.view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.beginAuthentication()
        }
    }
    
    // MARK: - Private Methods
    private func beginAuthentication() {
        if let _ = FRUser.currentUser {
            self.updateStatus()
            self.goToNext()
        } else {
            if currentNode == nil {
                self.hud.textLabel.text = "Calling journey"
                // Call the default Login Journey or the Biometrics Journey
                let journeyName =  (UserDefaults.standard.object(forKey: PebbleBankUtilities.biometricsEnabledKey) as? Bool ?? false) ? PebbleBankUtilities.biometricsAuthenticationJourney : PebbleBankUtilities.mainAuthenticationJourney
                
                FRSession.authenticate(authIndexValue: journeyName) { (result: Token?, node, error) in
                    self.handleNode(token: result, node: node, error: error)
                }
            } else {
                // Submit the Username/Password to AM
                guard let thisNode = currentNode else { return }
                var index = 0
                for textField in textFieldArray {
                    if let thisCallback: SingleValueCallback = thisNode.callbacks[index] as? SingleValueCallback {
                        thisCallback.setValue(textField.text)
                    }
                    index += 1
                }
                
                self.textFieldArray = [UITextField]()
                self.loginStackView.removeAllArrangedSubviews()
                self.step2StackView.alpha = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.step3StackView.alpha = 1.0
                    self.currentNode?.next { (token: Token?, node, error) in
                        self.handleNode(token: token, node: node, error: error)
                    }
                }
                
            }
        }
    }
    
    private func updateStatus() {
        DispatchQueue.main.async {
            if let _ = FRUser.currentUser {
                self.statusLabel?.text = "User is authenticated"
                self.nextButton.setTitle("Logout", for: .normal)
            }
            else {
                self.statusLabel?.text = "Welcome to Pebble Bank"
                self.nextButton.setTitle("Login", for: .normal)
            }
        }
    }
    
    private func goToNext() {
        self.performSegue(withIdentifier: "goToAuthenticated", sender: self)
    }
    
    @objc func handleTap() {
        self.view.endEditing(true)
    }
    
    @IBAction func loginButtonPressed(sender: UIButton) {
        print("Login button is pressed")
        self.hud.textLabel.text = "Authenticating"
        self.hud.show(in: self.view)
        self.step1StackView.alpha = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.beginAuthentication()
        }
    }
    
    func handleNode(token: Token?, node: Node?, error: Error?) {
        self.currentNode = node
        if let _ = token {
            print("User is authenticated")
            FRUser.currentUser?.getAccessToken(completion: { user, error in
                if error != nil {
                    print("User unable to get AccessToken with error: \(String(describing: error?.localizedDescription))")
                }
                DispatchQueue.main.async {
                    self.step4StackView.alpha = 1.0
                    self.hud.dismiss(afterDelay: 1.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.updateStatus()
                        self.goToNext()
                    }
                }
            })
        }
        else if let node = node {
            print("Node object received, handle the node")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.hud.dismiss()
                for callback: Callback in node.callbacks {
                    
                    let textField = UITextField(frame: CGRect.zero)
                    textField.autocorrectionType = .no
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.backgroundColor = .white
                    textField.textColor = .black
                    textField.autocapitalizationType = .none
                    textField.borderStyle = .roundedRect
                    
                    if let nameCallback = callback as? NameCallback {
                        textField.placeholder = nameCallback.prompt
                        self.loginStackView.addArrangedSubview(textField)
                        self.textFieldArray.append(textField)
                    }
                    if let passwordCallback = callback as? PasswordCallback {
                        textField.isSecureTextEntry = true
                        textField.placeholder = passwordCallback.prompt
                        self.loginStackView.addArrangedSubview(textField)
                        self.textFieldArray.append(textField)
                    }
                    
                    if let choiceCallback = callback as? ChoiceCallback {
                        let alert = UIAlertController(title: "Choice", message: choiceCallback.prompt, preferredStyle: .alert)
                        for choice in choiceCallback.choices {
                            let action = UIAlertAction(title: choice, style: .default) { (action) in
                                if let title = action.title, let index = choiceCallback.choices.firstIndex(of: title) {
                                    choiceCallback.setValue(index)
                                    node.next { (token: Token?, node, error) in
                                        self.handleNode(token: token, node: node, error: error)
                                    }
                                }
                            }
                            alert.addAction(action)
                        }
                        
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    if let authenticationCallback = callback as? WebAuthnAuthenticationCallback {
                        authenticationCallback.delegate = self
                        
                        // Note that the `Node` parameter in `.authenticate()` is an optional parameter.
                        // If the node is provided, the SDK automatically sets the assertion to the designated HiddenValueCallback
                        authenticationCallback.authenticate(node: node, usePasskeysIfAvailable: PebbleBankUtilities.usePasskeysIfAvailable) { (assertion) in
                            // Authentication is successful
                            // Submit the Node using Node.next()
                            node.next { (token: Token?, node, error) in
                                self.handleNode(token: token, node: node, error: error)
                            }
                        } onError: { (error) in
                            // An error occurred during the authentication process
                            // Submit the Node using Node.next()
                            let alert = UIAlertController(title: "WebAuthnError", message: "Something went wrong authenticating the device", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                node.next { (token: Token?, node, error) in
                                    self.handleNode(token: token, node: node, error: error)
                                }
                            })
                            alert.addAction(okAction)
                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                    
                    if let registrationCallback = callback as? WebAuthnRegistrationCallback {
                        registrationCallback.delegate = self
                        
                        // Note that the `Node` parameter in `.register()` is an optional parameter.
                        // If the node is provided, the SDK automatically sets the error outcome or attestation to the designated HiddenValueCallback
                        registrationCallback.register(node: node, deviceName: UIDevice.current.name, usePasskeysIfAvailable: PebbleBankUtilities.usePasskeysIfAvailable) { (attestation) in
                            // Registration is successful
                            // Submit the Node using Node.next()
                            node.next { (token: Token?, node, error) in
                                self.handleNode(token: token, node: node, error: error)
                            }
                        } onError: { (error) in
                            // An error occurred during the registration process
                            // Submit the Node using Node.next()
                            let alert = UIAlertController(title: "WebAuthnError", message: "Something went wrong registering the device", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                node.next { (token: Token?, node, error) in
                                    self.handleNode(token: token, node: node, error: error)
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
        }
        else {
            print ("Something went wrong: \(String(describing: error))")
        }
    }
}

extension LoginViewController: PlatformAuthenticatorRegistrationDelegate, PlatformAuthenticatorAuthenticationDelegate {
    func localKeyExistsAndPasskeysAreAvailable() {}
    
    // MARK: PlatformAuthenticatorRegistrationDelegate
    
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Exclude Credentials", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Create Credentials", message: "KeyName: \(keyName) | Relying Party Name: \(rpName) | User Name: \(userName)", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)
        
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: PlatformAuthenticatorAuthenticationDelegate
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
        
        if actionSheet.popoverPresentationController != nil {
            actionSheet.popoverPresentationController?.sourceView = self.view
            actionSheet.popoverPresentationController?.sourceRect = self.view.bounds
        }
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
}
