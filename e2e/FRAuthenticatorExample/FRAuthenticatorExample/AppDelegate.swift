//
//  AppDelegate.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2020 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FRALog.setLogLevel(.all)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in }
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FRAPushHandler.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        FRAPushHandler.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let notification = FRAPushHandler.shared.application(application, didReceiveRemoteNotification: userInfo),
              let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
              let window = sceneDelegate.window,
              let rootViewController = window.rootViewController,
              let viewController = sb.instantiateViewController(withIdentifier: "NotificationRequestViewControllerId") as? NotificationRequestViewController
        else { return }

        if FRAClient.shared == nil {
            FRAClient.start()
        }

        viewController.notification = notification
        var currentController = rootViewController
        while let presentedController = currentController.presentedViewController {
            currentController = presentedController
        }

        if currentController.isKind(of: NotificationRequestViewController.self),
           let newCurrentController = currentController.presentingViewController {
            currentController.dismiss(animated: false)
            currentController = newCurrentController
        }

        currentController.present(viewController, animated: true)
    }
}
