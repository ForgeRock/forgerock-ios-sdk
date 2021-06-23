//
//  FRUI.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

/// FRUI framework is mainly responsible to provide demonstration of FRAuth framework's functionalities with pre-built User Interfaces. FRUI constructs and builds screens, and provides an abilities to customize and style those pre-built screens and UI(s) for developers' needs
public final class FRUI {
    
    //  MARK: - Properties
    
    /// Singleton object instance
    public static let shared = FRUI()
    /// Primary color
    public var primaryColor: UIColor
    /// Primary text color
    public var primaryTextColor: UIColor
    /// Secondary color
    public var secondaryColor: UIColor
    /// Error color
    public var errorColor: UIColor
    /// Warning color
    public var warningColor: UIColor
    /// Logo image
    public var logoImage: UIImage?
    
    //  MARK: - Init
    
    /// Private initialization method
    private init() {
        self.primaryColor = UIColor.hexStringToUIColor(hex: "#519387")
        self.primaryTextColor = UIColor.hexStringToUIColor(hex: "#495661")
        self.secondaryColor = UIColor.hexStringToUIColor(hex: "#fef151")
        self.errorColor = UIColor.hexStringToUIColor(hex: "#f94c23")
        self.warningColor = UIColor.hexStringToUIColor(hex: "#fef151")
    
        #if SWIFT_PACKAGE
        self.logoImage = UIImage(named: "forgerock-logo", in: Bundle.module, compatibleWith: nil)
        #else
        self.logoImage = UIImage(named: "forgerock-logo", in: Bundle(for: FRUI.self), compatibleWith: nil)
        #endif
    }
}

extension UIColor {
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
