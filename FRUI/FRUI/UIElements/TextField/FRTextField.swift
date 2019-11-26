//
//  FRTextField.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

@objc
public class FRTextField: UITextField {
    
    @objc public var titleFont: UIFont = .systemFont(ofSize: 12)
    @objc public var errorColor: UIColor = UIColor.red
    @objc public var normalColor: UIColor = UIColor.blue
    @objc public var unselectedColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor(named: "LightGray") ?? UIColor.lightGray
            }
            else {
                return UIColor.lightGray
            }
        }
    }
    
    @objc public var errorMessage: String? {
        didSet {
            updateAppearance()
        }
    }
    
    @objc override public var text: String? {
        didSet {
            updateAppearance()
        }
    }
    
    @objc override public var placeholder: String? {
        didSet {
            if let thisPlaceholder = placeholder, thisPlaceholder.count > 0 {
                cachedPlaceholder = thisPlaceholder
            }
        }
    }
    
    @objc override public var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    var _errorMessage: String?
    var titleLabel: UILabel!
    var lineView: UIView!
    var isSelectedOrFocused: Bool = false
    var cachedPlaceholder: String?
    
    var isError: Bool {
        get {
            if let errText = self.errorMessage, errText.count > 0 {
                return true
            }
            else {
                return false
            }
        }
    }
    
    // - MARK: Init
    @objc
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initPrivate()
    }
    
    @objc
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initPrivate()
    }
    
    fileprivate final func initPrivate() {
        
        borderStyle = .none
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        titleLabel.alpha = 0.0
        titleLabel.textColor = normalColor
        titleLabel.font = titleFont
        titleLabel.frame = self.bounds
        addSubview(titleLabel)
        self.titleLabel = titleLabel
        
        // Line View
        let lineView = UIView()
        lineView.isUserInteractionEnabled = false
        lineView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addSubview(lineView)
        self.lineView = lineView
        
        // Add Observer
        self.addTarget(self, action: #selector(editingStatusChanged), for: .editingChanged)
        self.updateAppearance()
    }
    
    
    deinit {
        self.removeTarget(self, action: #selector(editingStatusChanged), for: .editingChanged)
    }
    
    
    // - MARK: Appearance
    
    @objc func editingStatusChanged() {
        updateAppearance()
    }
    
    
    func updateAppearance() {
        updateLineViewAppearance()
        updateTitleAppearance()
    }
    
    
    func updateLineViewAppearance() {
        let lineViewHeight: CGFloat = isSelectedOrFocused ? 2.0 : 1.0
        self.lineView.backgroundColor = isError ? errorColor : isSelectedOrFocused ? normalColor : unselectedColor
        self.lineView.frame = CGRect(x: 0, y: bounds.size.height - lineViewHeight, width: bounds.size.width, height: lineViewHeight)
    }
    
    
    func updateTitleAppearance() {
        
        self.titleLabel.text = self.titleText()
        self.titleLabel.textColor = normalColor
        
        if isError {
            titleLabel.text = titleText()
            titleLabel.textColor = errorColor
            self.titleLabel.alpha = 1.0
            updateTexts(true)
        }
        else if isSelectedOrFocused {
            if self.titleLabel.alpha == 0.0 {
                updateTexts(true)
                self.titleLabel.alpha = 1.0
                placeholder = nil
            }
        }
        else {
            if let currTxt = self.text, currTxt.count > 0 {
                self.titleLabel.textColor = unselectedColor
                if titleLabel.alpha == 0.0 {
                    updateTexts(true)
                    self.titleLabel.alpha = 1.0
                }
            } else if self.titleLabel.alpha == 1.0, !isError {
                updateTexts(false)
                self.titleLabel.alpha = 0.0
                placeholder = cachedPlaceholder
            }
        }
    }
    
    
    // - MARK: Title Text / Display
    
    func titleText() -> String {
        if let errMsg = self.errorMessage, errMsg.count > 0 {
            return errMsg
        }
        else if let placeHolderText = cachedPlaceholder ?? placeholder {
            return placeHolderText
        }
        else {
            return ""
        }
    }
    
    
    func updateTexts(_ shouldShow: Bool = false) {
        let titleLineHeight = self.titleLabel.font.lineHeight
        let titleYOrigin = shouldShow ? 0 : titleLineHeight
        let titleFrame = shouldShow ? CGRect(x: 0, y: titleYOrigin, width: bounds.size.width, height: titleLineHeight) : bounds
        
        let updateBlock = { () -> Void in
            self.titleLabel.frame = titleFrame
        }
        
        let animationOptions: UIView.AnimationOptions = shouldShow ? .curveEaseOut : .curveEaseIn
        UIView.animate(withDuration: 0.3, delay: 0.0, options: animationOptions, animations: {
            () -> Void in
            updateBlock()
        }, completion: nil)
    }
    
    // - MARK: Responder
    
    @discardableResult
    override open func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        isSelectedOrFocused = true
        updateAppearance()
        return result
    }
    
    
    @discardableResult
    override open func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        isSelectedOrFocused = false
        updateAppearance()
        return result
    }
    
    
    // - MARK: UITextField drawing
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.textRect(forBounds: bounds)
        let titleHeight = self.titleLabel.font.lineHeight
        
        let rect = CGRect(
            x: superRect.origin.x,
            y: titleHeight,
            width: superRect.size.width,
            height: superRect.size.height - titleHeight - 0.0
        )
        return rect
    }
    
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.editingRect(forBounds: bounds)
        let titleHeight = self.titleLabel.font.lineHeight
        
        let rect = CGRect(
            x: superRect.origin.x,
            y: titleHeight,
            width: superRect.size.width,
            height: superRect.size.height - titleHeight - 0.0
        )
        return rect
    }
    
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = CGRect(
            x: 0,
            y: self.titleLabel.font.lineHeight,
            width: bounds.size.width,
            height: bounds.size.height - self.titleLabel.font.lineHeight - 0.0
        )
        return rect
    }
}
