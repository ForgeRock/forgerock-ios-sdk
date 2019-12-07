//
//  FRDropDownView.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit

@objc
public protocol FRDropDownViewProtocol {
    @objc
    func selectedItem(index: Int, item: String)
}

class FRDropDownView: UIView {
    
    // - MARK: Public Properties
    
    var contentHeight: CGFloat {
        get {
            return self.tableView.contentSize.height
        }
    }
    
    var rowHeight: CGFloat {
        set {
            _rowHeight = newValue
            tableView.rowHeight = newValue
        }
        get {
            return _rowHeight
        }
    }
    
    var _rowHeight: CGFloat = 40.0
    var viewColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.systemGray4
            }
            else {
                return UIColor(white: 0.89, alpha: 1)
            }
        }
    }
    
    var cellFont: UIFont?
    var dataSource: [String] = []
    var delegate: FRDropDownViewProtocol?
    
    // - MARK: Private Properties
    fileprivate var tableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initPrivate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initPrivate()
    }
    
    func initPrivate() {
        tableView.rowHeight = 40.0
        tableView.dataSource = self
        tableView.delegate = self
        
        addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        let bcView = UIView(frame: tableView.bounds)
        bcView.backgroundColor = viewColor
        tableView.backgroundView = bcView
        tableView.separatorStyle = .none
        
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 3.0
        self.layer.masksToBounds = false
    }
    
    override func layoutSubviews() {
        tableView.separatorStyle = .none
        super.layoutSubviews()
    }
}


extension FRDropDownView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dataSource[indexPath.row]
        cell.textLabel?.font = cellFont
        cell.backgroundColor = viewColor
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.selectedItem(index: indexPath.row, item: dataSource[indexPath.row])
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}
