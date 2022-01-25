//
// Copyright (c) 2022 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FRLog.setLogLevel([.error, .network])
        
        do {
            try FRAuth.start()
            print("SDK initialized successfully")
        }
        catch {
            print(error)
        }
        
        self.updateStatus()
    }
    
    func updateStatus() {
        let isUserLoggedIn = FRUser.currentUser != nil
        
        statusLabel.text = isUserLoggedIn ? "User is authenticated" : "User is not authenticated"
        loginButton.isEnabled = !isUserLoggedIn
        logoutButton.isEnabled = isUserLoggedIn
    }
    
    func handleNode(user: FRUser?, node: Node?, error: Error?) {
        if let _ = user {
            print("User is authenticated")
            
            DispatchQueue.main.async {
                self.updateStatus()
            }
        }
        else if let node = node {
            print("Node object received, handle the node")
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "User Authentication", message: nil, preferredStyle: .alert)
                for callback: Callback in node.callbacks {
                    if callback.type == "NameCallback", let nameCallback = callback as? NameCallback {
                        
                        alert.addTextField { (textField) in
                            textField.placeholder = nameCallback.prompt
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        }
                        
                    }
                    else if callback.type == "PasswordCallback", let passwordCallback = callback as? PasswordCallback {
                        alert.addTextField { (textField) in
                            textField.placeholder = passwordCallback.prompt
                            textField.isSecureTextEntry = true
                            textField.autocorrectionType = .no
                            textField.autocapitalizationType = .none
                        }
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let submitAction = UIAlertAction(title: "Next", style: .default) { (_) in
                    if let textfields = alert.textFields {
                        for (index, textField) in textfields.enumerated() {
                            if let thisCallback = node.callbacks[index] as? SingleValueCallback {
                                thisCallback.setValue(textField.text)
                            }
                        }
                    }
                    
                    node.next { (user: FRUser?, node, error) in
                        self.handleNode(user: user, node: node, error: error)
                    }
                }
                
                alert.addAction(cancelAction)
                alert.addAction(submitAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        else {
            print ("Something went wrong: \(String(describing: error))")
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        print("Login button is pressed")
        
        FRUser.login {(user: FRUser?, node, error) in
            self.handleNode(user: user, node: node, error: error)
        }
        
        DispatchQueue.main.async {
            self.updateStatus()
        }
        
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        print("Logout button is pressed")
        
        FRUser.currentUser?.logout()
        
        DispatchQueue.main.async {
            self.updateStatus()
        }
    }
    
}
