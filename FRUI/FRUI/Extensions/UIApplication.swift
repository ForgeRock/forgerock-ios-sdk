// 
//  UIApplication.swift
//  FRUI
//
//  Copyright (c) 2019 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import UIKit


extension UIApplication {
    
    var visibleViewController: UIViewController? {
        
        // Check root viewController from keyWindow first
        guard let rootViewController = keyWindow?.rootViewController else {
            return nil
        }
        
        // Iterate from rootViewController to make sure whether root viewcontroller is on the top or not
        return getVisibleViewController(rootViewController)
    }
    
    private func getVisibleViewController(_ viewController: UIViewController) -> UIViewController? {
        
        if let presentedViewController = viewController.presentedViewController {
            return getVisibleViewController(presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController.visibleViewController
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController.selectedViewController
        }
        
        return viewController
    }
}
