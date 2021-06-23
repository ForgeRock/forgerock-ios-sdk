// 
//  IdPCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2021 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class IdPCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    
    public static let cellIdentifier = "IdPCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 54.0
    public var presentingViewController: UIViewController?
    var callback: IdPCallback?
    var delegate: AuthStepProtocol?
    
    //  MARK: - IBOutlet
    
    @IBOutlet weak var descriptionLabel: UILabel?
    
    
    //  MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.descriptionLabel?.textColor = FRUI.shared.primaryTextColor
    }
    
    
    //  MARK: - Protocol
    
    func updateCellData(callback: Callback) {
        
        if let idpCallback = callback as? IdPCallback {
            self.callback = idpCallback
            self.descriptionLabel?.text = "Signing-in with \(idpCallback.idpClient.provider)"
            idpCallback.signIn(presentingViewController: self.presentingViewController) { (token, tokenType, error) in
                
                if let error = error {
                    FRLog.e("An error occurred from IdPHandler.signIn: \(error.localizedDescription)")
                }
                else {
                    if let _ = token, let tokenType = tokenType {
                        FRLog.v("Credentials received - Token Type: \(tokenType) from \(idpCallback.idpClient.provider)")
                    }
                    FRLog.v("Social Login Provider credentials received; submitting the authentication tree to proceed")
                    self.delegate?.submitNode()
                }
            }
        }
    }
}
