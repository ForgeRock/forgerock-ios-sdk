//
//  AccountDetailTableViewController.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class ExportAccountsViewController: BaseViewController {
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    var qrCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Export Accounts"
        
        
        guard let qrCodeImage = generateQRCode(from: qrCode) else {
            displayAlert(title: "Invalid QR Code", message: "Unable to generate a QR Code Image")
            return
        }
        qrCodeImageView.image = qrCodeImage
        qrCodeImageView.layer.magnificationFilter = CALayerContentsFilter.nearest
    }
    
    
    //  MARK: - IBAction
    @IBAction func close(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let QRFilter = CIFilter(name: "CIQRCodeGenerator") {
            QRFilter.setValue(data, forKey: "inputMessage")
            guard let QRImage = QRFilter.outputImage else {return nil}
            return UIImage(ciImage: QRImage)
        }
        return nil
    }
}

