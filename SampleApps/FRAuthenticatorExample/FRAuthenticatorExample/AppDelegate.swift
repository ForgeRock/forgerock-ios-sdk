//
//  AppDelegate.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020-2022 ForgeRock. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator
import FRCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var privacyScreen: UIImageView = UIImageView()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FRALog.setLogLevel(.all)
        RequestInterceptorRegistry.shared.registerInterceptors(interceptors: [PushInterceptor()])
       
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        application.registerForRemoteNotifications()
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
}

class PushInterceptor: RequestInterceptor {
    func intercept(request: Request, action: Action) -> Request {
        if action.type == "PUSH_REGISTER" {
          
          // Add additional header:
            var headers = request.headers
            headers["x-Gateway-APIKey"] = "true"

            // Construct the updated request:
            let newRequest = Request(
                url: request.url,
                method: request.method,
                headers: headers,
                bodyParams: request.bodyParams,
                urlParams: request.urlParams,
                requestType: request.requestType,
                responseType: request.responseType,
                timeoutInterval: request.timeoutInterval
            )
            return newRequest
        }
        else {
            return request
        }
    }
}
