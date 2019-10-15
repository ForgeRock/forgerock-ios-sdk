//
//  FRButton.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

@objc
public class FRButton: UIButton {
    
    private var animator = UIViewPropertyAnimator()
    private var _titleColor: UIColor = UIColor.black
    
    @objc public var titleColor: UIColor {
        set {
            self.setTitleColor(newValue, for: .normal)
            self.setTitleColor(newValue, for: .highlighted)
            self.setTitleColor(newValue, for: .selected)
            _titleColor = newValue
        }
        
        get {
            return _titleColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        privateInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        privateInit()
    }
    
    private func privateInit() {
        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 3.0
        self.layer.masksToBounds = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc private func touchDown() {
        self.flash()
    }
    
    func flash() {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 0.2
        flash.fromValue = 1
        flash.toValue = 0.95
        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        flash.autoreverses = true
        flash.repeatCount = 1
        layer.add(flash, forKey: nil)
    }
}
