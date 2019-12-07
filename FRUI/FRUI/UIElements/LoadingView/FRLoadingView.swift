//
//  FRLoadingView.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

@objc
public class FRLoadingView: UIView {
    
    @objc public var spacing: CGFloat = 15.0
    @objc public var colors: [UIColor] = [UIColor.hexStringToUIColor(hex: "#f94c23"), UIColor.hexStringToUIColor(hex: "#fef151"), UIColor.hexStringToUIColor(hex: "#519387"), UIColor.hexStringToUIColor(hex: "#495661")]
    @objc public var showDropShadow = true
    @objc public var showDimmedBackground = true
    @objc public var loadingText: String?
    
    var squareViews: [UIView] = []
    var timer: Timer?
    var currentIndex = 0
    var isLoading: Bool = false
    var isRotating: Bool = false
    var loadingTextFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: 15)!
    var backgroundView: UIView = UIView()
    var labelColor: UIColor = UIColor.hexStringToUIColor(hex: "#282828")
    
    @objc
    public init(size: CGSize, showDropShadow: Bool, showDimmedBackground: Bool, loadingText: String?) {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        super.init(frame: rect)
        self.loadingText = loadingText
        self.showDimmedBackground = showDimmedBackground
        self.showDropShadow = showDropShadow
        initPrivate()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initPrivate()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initPrivate()
    }
    
    private func initPrivate() {
        
        if #available(iOS 13.0, *) {
            self.backgroundColor = UIColor.systemGray6
            self.labelColor = UIColor.label
        }
        else {
            self.backgroundColor = UIColor.white
        }
        
        self.alpha = 0.0
        
        if self.showDropShadow {
            self.layer.cornerRadius = 5;
            self.layer.masksToBounds = true;
            
            self.layer.cornerRadius = 8.0
            self.clipsToBounds = true
            self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
            self.layer.shadowOffset = CGSize(width: 0, height: 1)
            self.layer.shadowOpacity = 1.0
            self.layer.shadowRadius = 3.0
        }
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if showDimmedBackground {
            backgroundView.backgroundColor = UIColor.lightGray
        }
        else {
            backgroundView.backgroundColor = UIColor.clear
        }
        
        backgroundView.alpha = 0.0
        backgroundView.bringSubviewToFront(self)
        backgroundView.isHidden = true
    }
    
    deinit {
        isRotating = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override public func draw(_ rect: CGRect) {
        
        var labelYOrigin: CGFloat = bounds.height
        
        if let loadingText = self.loadingText {
            labelYOrigin = bounds.height - loadingTextFont.lineHeight - spacing * 2
            let loadingLabel = UILabel(frame: CGRect(x: 0, y: labelYOrigin, width: bounds.width, height: loadingTextFont.lineHeight))
            loadingLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            loadingLabel.textAlignment = .center
            loadingLabel.font = loadingTextFont
            loadingLabel.textColor = self.labelColor
            loadingLabel.text = loadingText
            addSubview(loadingLabel)
        }
        
        let width = (bounds.width - (CGFloat(colors.count) * spacing) - spacing) / CGFloat(colors.count)
        let yOrigin = (labelYOrigin - width) / 2
        
        for (index, color) in colors.enumerated() {
            let squareView = UIView(frame: CGRect(x: ((spacing + width) * CGFloat(index)) + spacing, y: yOrigin, width: width, height: width))
            squareView.backgroundColor = color
            squareViews.append(squareView)
            addSubview(squareView)
        }
    }
    
    @objc
    public func add(inView: UIView) {
        if !inView.subviews.contains(backgroundView) {
            
            backgroundView.frame = inView.bounds
            inView.addSubview(backgroundView)
            inView.addSubview(self)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.widthAnchor.constraint(equalToConstant: self.frame.size.width).isActive = true
            self.heightAnchor.constraint(equalToConstant: self.frame.size.height).isActive = true
            self.centerXAnchor.constraint(equalTo: inView.centerXAnchor).isActive = true
            self.centerYAnchor.constraint(equalTo: inView.centerYAnchor).isActive = true
            
        }
    }
    
    @objc
    public func startLoading() {
        
        guard isRotating == false else {
            return
        }

        isRotating = true
        
        UIView.animate(withDuration: 1.0, animations: {
            self.backgroundView.alpha = 0.4
            self.backgroundView.isHidden = false
            self.alpha = 0.9
            self.isHidden = false
        })
        
        currentIndex = 0
        timer = Timer.scheduledTimer(timeInterval: Double(0.2), target: self, selector: #selector(startAnimation), userInfo: nil, repeats: true)
    }
    
    @objc
    func startAnimation() {
        
        if currentIndex >= colors.count {
            currentIndex = 0
        }
        
        let view = squareViews[currentIndex]
        UIView.animate(withDuration: TimeInterval(0.2), delay: 0.0, animations: {
            view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (finished) in
            UIView.animate(withDuration: TimeInterval(0.2), animations: {
                view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }
        
        currentIndex += 1
    }
    
    @objc
    public func stopLoading() {
        
        guard isRotating else {
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.alpha = 0.0
            self.backgroundView.isHidden = true
            self.alpha = 0.0
            self.isHidden = true
        })
        
        isRotating = false
        timer?.invalidate()
        timer = nil
    }
    
    private func rotate(view: UIView, rotateTime: Double) {
        
        guard isRotating else {
            return
        }
        
        UIView.animate(withDuration: rotateTime/2, delay: 0.0, options: .curveLinear, animations: {
            view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        }, completion: { finished in
            UIView.animate(withDuration: rotateTime/2, delay: 0.0, options: .curveLinear, animations: {
                view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi*2))
            }, completion: { finished in
                self.rotate(view: view, rotateTime: rotateTime)
            })
        })
    }
}

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = .greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}
