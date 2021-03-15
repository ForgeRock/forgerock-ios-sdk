//
//  FRDropDownButton.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

@objc
public class FRDropDownButton: UIButton {
    
    @objc
    public var themeColor: UIColor {
        set {
            lineView.backgroundColor = newValue
            setTitleColor(newValue, for: .normal)
            setTitleColor(newValue, for: .highlighted)
            setTitleColor(newValue, for: .focused)
            setTitleColor(newValue, for: .selected)
            setTitleColor(newValue, for: .disabled)
            _themeColor = newValue
            indicatorView.setImageColor(color: newValue)
        }
        get {
            return _themeColor
        }
    }
    
    @objc
    public var dataSource: [String] {
        set {
            dropDownView.dataSource = newValue
        }
        get {
            return dropDownView.dataSource
        }
    }
    
    @objc
    public var itemHeigh: CGFloat {
        set {
            dropDownView.rowHeight = newValue
        }
        get {
            return dropDownView.rowHeight
        }
    }
    
    @objc
    public var shouldCoverButton: Bool {
        set {
            _shouldCoverButton = newValue
            configureLayouts()
        }
        get {
            return _shouldCoverButton
        }
    }
    @objc public var delegate: FRDropDownViewProtocol?
    @objc public var buttonFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: 15)!
    @objc public var maxHeight: CGFloat = 150.0
    
    fileprivate var _shouldCoverButton: Bool = false
    fileprivate var _themeColor: UIColor = UIColor.clear
    #if SWIFT_PACKAGE
    fileprivate var indicatorView: UIImageView = UIImageView(image: UIImage(named: "arrow.png", in: Bundle.module, compatibleWith: nil))
    #else
    fileprivate var indicatorView: UIImageView = UIImageView(image: UIImage(named: "arrow.png", in: Bundle.init(for: FRDropDownButton.self), compatibleWith: nil))
    #endif
    fileprivate var dropDownView: FRDropDownView = FRDropDownView(frame: CGRect.zero)
    fileprivate var isVisible: Bool = false
    fileprivate var heightConstraint = NSLayoutConstraint()
    fileprivate var lineView: UIView = UIView()
    fileprivate var isInitialLoading: Bool = true
    
    @objc
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initPrivate()
    }
    
    @objc
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initPrivate()
    }
    
    func initPrivate() {
        dropDownView.delegate = self
        backgroundColor = UIColor.clear
        indicatorView.backgroundColor = UIColor.clear
        titleLabel?.font = buttonFont
        dropDownView.cellFont = buttonFont
    }
    
    public override func didMoveToSuperview() {
        
        super.didMoveToWindow()
        
        guard isInitialLoading else {
            return
        }
        
        isInitialLoading = false
        self.superview?.addSubview(dropDownView)
        self.superview?.bringSubviewToFront(dropDownView)
        
        addSubview(indicatorView)
        bringSubviewToFront(indicatorView)
        
        addSubview(lineView)
        bringSubviewToFront(lineView)
        
        configureLayouts()
    }
    
    func configureLayouts() {
        dropDownView.translatesAutoresizingMaskIntoConstraints = false
        
        dropDownView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        dropDownView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropDownView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        heightConstraint = dropDownView.heightAnchor.constraint(equalToConstant: 0)
        
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        indicatorView.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        indicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicatorView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: 0).isActive = true
        
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        lineView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        lineView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isVisible {
            close()
        }
        else {
            open()
        }
    }
    
    @objc
    public func open() {
        guard !isVisible else {
            return
        }
        
        indicatorView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
        isVisible = true
        NSLayoutConstraint.deactivate([heightConstraint])
        heightConstraint.constant = (dropDownView.contentHeight < maxHeight) ? dropDownView.contentHeight : maxHeight
        NSLayoutConstraint.activate([heightConstraint])
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: .curveEaseInOut, animations: {
            self.dropDownView.layoutIfNeeded()
            self.dropDownView.center.y += self.dropDownView.frame.height / 2
        }, completion: nil)
    }
    
    @objc
    public func close() {
        guard isVisible else {
            return
        }
        
        indicatorView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 2));
        isVisible = false
        NSLayoutConstraint.deactivate([heightConstraint])
        heightConstraint.constant = 0
        NSLayoutConstraint.activate([heightConstraint])
        UIView.animate(withDuration: 0.3) {
            self.dropDownView.center.y -= self.dropDownView.frame.height / 2
            self.dropDownView.layoutIfNeeded()
        }
    }
    
}

extension FRDropDownButton: FRDropDownViewProtocol {
    public func selectedItem(index: Int, item: String) {
        self.delegate?.selectedItem(index: index, item: item)
        setTitle(item, for: .normal)
        setTitle(item, for: .highlighted)
        setTitle(item, for: .focused)
        setTitle(item, for: .selected)
        close()
    }
}


extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}
