// 
//  FRUITextView.swift
//  FRUI
//
//  Copyright (c) 2020 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import UIKit

extension UITextView {
    func setHTMLString(_ value: String) {
        if let stringData = value.data(using: .utf8) {
            do {
                let attributedString = try NSAttributedString(data: stringData, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                self.attributedText = attributedString
            }
            catch {
                self.text = value
            }
        }
        else {
            self.text = value
        }
    }
}
