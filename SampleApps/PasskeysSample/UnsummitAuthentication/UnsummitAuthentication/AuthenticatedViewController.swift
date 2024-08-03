//
//  AuthenticatedViewController.swift
//  UnsummitAuthentication
//
//  Created by George Bafaloukas on 10/05/2022.
//

import UIKit
import FRAuth
import JGProgressHUD

class AuthenticatedViewController: UIViewController {

    @IBOutlet weak var pebbleLogo: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var logoutButton: UIButton!
    
    private var infoText: String = ""
    private let hud = JGProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.updateStatus()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.pebbleLogo.addGestureRecognizer(tap)
        self.infoTextView.alpha = 0.0
        view.addGestureRecognizer(tap)
    }
    
    @objc func handleTap() {
        UIView.animate(withDuration: 1.0, delay: 0.1, options: [], animations: {
            self.infoTextView.alpha = 1.0
            self.pebbleLogo.alpha = 0.0
        }, completion: nil)
    }
    
    @IBAction func SettingsAction(_ sender: Any) {
        self.performSegue(withIdentifier: "OpenSettings", sender: self)
    }
    
    // MARK: - Private Methods
    
    private func updateStatus() {
        if let user = FRUser.currentUser {
            self.hud.textLabel.text = "Loading user info"
            self.hud.show(in: self.view)
            // Call the User Info endpoint and parse the results
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                user.getUserInfo { userInfoObject, error in
                    if let userInfoObject = userInfoObject {
                        self.infoText = "User is authenticated \n \n \n"
                        self.infoText = self.infoText + (userInfoObject.userInfo.debugDescription) + "\n \n"
                        self.infoText = self.infoText + (user.token?.debugDescription ?? "") + "\n \n"
                        self.updateText(userInfoObject)
                    } else {
                        self.logOutAndDismiss()
                    }
                }
            }
            
        }
    }
    
    private func updateText(_ userInfoObject: UserInfo) {
        DispatchQueue.main.async {
            self.nameLabel.text = "Welcome \(userInfoObject.name ?? "")"
            self.infoTextView.text = self.infoText
            self.hud.dismiss()
        }
    }
    
    private func logOutAndDismiss() {
        self.hud.textLabel.text = "Loging out"
        self.hud.show(in: self.view)
        FRUser.currentUser?.logout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hud.dismiss(animated: true)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        // Call Logout and navigate back
        self.logOutAndDismiss()
    }

}
