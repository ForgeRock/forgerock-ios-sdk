//
//  PollingWaitCallbackTableViewCell.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuth

class PollingWaitCallbackTableViewCell: UITableViewCell, FRUICallbackTableViewCell {

    // MARK: - Properties
    public static let cellIdentifier = "PollingWaitCallbackTableViewCellId"
    public static let cellHeight: CGFloat = 140.0
    public var delegate: AuthStepProtocol?
    var loadingView: FRLoadingView?
    var loaded: Bool = false
    
    var callback: PollingWaitCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        loadingView = FRLoadingView(size: CGSize(width: 120.0, height: 120.0), showDropShadow: false, showDimmedBackground: false, loadingText: "")
        loadingView?.add(inView: self.contentView)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Public
    public func updateCellData(callback: Callback) {
        self.callback = callback as? PollingWaitCallback
        loadingView?.loadingText = self.callback?.message
        loadingView?.startLoading()
        
        if let waitTime = self.callback?.waitTime {
            if !loaded {
                loaded = true
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(waitTime/1000)) {
                    self.delegate?.submitNode()
                }
            }
        }
    }
}
