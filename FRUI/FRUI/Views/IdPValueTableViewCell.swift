// 
//  IdPValueTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit
import FRAuth

class IdPValueTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    //  MARK: - Properties
    public static let cellIdentifier = "IdPValueTableViewCellId"
    public static let cellHeight: CGFloat = 54.0
    var delegate: AuthStepProtocol?
    
    
    //  MARK: - IBOutlet
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var buttonContainerview: UIView?
    
    
    //  MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.descriptionLabel?.textColor = FRUI.shared.primaryTextColor
    }
    
    
    //  MARK: - Protocols
    
    func updateCellData(callback: Callback) {
        
    }
    
    func updateCellWithProvider(provider: IdPValue) {
        
        if provider.provider.lowercased().contains("apple") {
            let handler = AppleSignInHandler()
            if let buttonView = handler.getProviderButtonView(), let containerView = self.buttonContainerview {
                self.adjustButtonView(buttonView: buttonView, containerView: containerView)
                return
            }
        }
        else if provider.provider.lowercased().contains("google") {
            if let c: NSObject.Type = NSClassFromString("FRGoogleSignIn.GoogleSignInHandler") as? NSObject.Type, let thisHandler = c.init() as? IdPHandler, let buttonView = thisHandler.getProviderButtonView(), let containerView = self.buttonContainerview {
                self.adjustButtonView(buttonView: buttonView, containerView: containerView)
                return
            }
        }
        else if provider.provider.lowercased().contains("facebook") {
            if let c: NSObject.Type = NSClassFromString("FRFacebookSignIn.FacebookSignInHandler") as? NSObject.Type, let thisHandler = c.init() as? IdPHandler, let buttonView = thisHandler.getProviderButtonView(), let containerView = self.buttonContainerview {
                self.adjustButtonView(buttonView: buttonView, containerView: containerView)
                return
            }
        }
        var providerName = provider.provider
        if let displayName = provider.uiConfig?["buttonDisplayName"] {
            providerName = displayName
        }
        self.descriptionLabel?.text = "Sign in with \(providerName)"
    }
    
    
    //  MARK: - Helper methods
    
    func adjustButtonView(buttonView: UIView, containerView: UIView) {
        buttonView.isUserInteractionEnabled = false
        buttonView.frame = containerView.bounds
        containerView.addSubview(buttonView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.widthAnchor.constraint(equalToConstant: containerView.frame.size.width).isActive = true
        buttonView.heightAnchor.constraint(equalToConstant: containerView.frame.size.height).isActive = true
        buttonView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        buttonView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
    }
}
