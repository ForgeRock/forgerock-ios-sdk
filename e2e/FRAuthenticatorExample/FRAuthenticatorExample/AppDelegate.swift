//
//  AppDelegate.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020-2023 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var privacyScreen: UIImageView = UIImageView()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FRALog.setLogLevel(.all)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        application.registerForRemoteNotifications()
        
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            NSLog("App launched with deeplink: \(url.absoluteString)")
            createMechanismFromUri(uri: url)
        }
        
        return true
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        let blurredImg = captureBlurredScreenshot()
        privacyScreen = UIImageView(image: blurredImg)
        self.window?.addSubview(privacyScreen)
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        privacyScreen.removeFromSuperview()
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FRAPushHandler.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        FRAPushHandler.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let sb : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let notification = FRAPushHandler.shared.application(application, didReceiveRemoteNotification: userInfo),
            let window = self.window, let rootViewController = window.rootViewController,
            let viewController: NotificationRequestViewController = sb.instantiateViewController(withIdentifier: "NotificationRequestViewControllerId") as? NotificationRequestViewController {
            
            if FRAClient.shared == nil {
                FRAClient.start()
            }
            
            viewController.notification = notification
            var currentController = rootViewController
            while let presentedController = currentController.presentedViewController {
                currentController = presentedController
            }
            
            //prevent from showing the same NotificationRequestViewController twice when opened from tapping a push notification
            if currentController.isKind(of: NotificationRequestViewController.self), let newCurrentController = currentController.presentingViewController {
                currentController.dismiss(animated: false)
                currentController = newCurrentController
            }
            
            currentController.present(viewController, animated: true)
        }
    }
    

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        NSLog("App opened with deeplink: \(url.absoluteString)")
        createMechanismFromUri(uri: url)
        
        return true
    }
    
    
    //  MARK: - Helper
    
    func captureBlurredScreenshot() -> UIImage? {
        //  Capture current screenshot
        let size = self.window?.screen.bounds.size ?? CGSize()
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        self.window?.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //  Convert image to CIImage
        guard let screenshotImg = image, let inputImage = CIImage(image: screenshotImg) else {
            return nil
        }
        //  Apply blurred filter
        let gaussianFilter = CIFilter(name: "CIBokehBlur")
        gaussianFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        gaussianFilter?.setValue(10, forKey: kCIInputRadiusKey)
            
        guard let outputImage = gaussianFilter?.outputImage else {
            return nil
        }
            
        return UIImage(ciImage: outputImage)
    }
    
    
    private func createMechanismFromUri(uri: URL) {
        FRAClient.shared?.createMechanismFromUri(uri: uri, onSuccess: { mechanism in
            NSLog("Successfully created a mechanism with deeplink: \(uri.absoluteString)");
            DispatchQueue.main.async {
                if let window = self.window,
                   let rootViewController = window.rootViewController as? UINavigationController,
                   let mainListViewCointroller = rootViewController.viewControllers.first as? MainListViewController {
                    mainListViewCointroller.reload()
                }
            }
        }, onError: { error in
            NSLog("Error creating a mechanism with deeplink: \(uri.absoluteString)");
        })
    }
}
