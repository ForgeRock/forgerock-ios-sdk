//
//  SceneDelegate.swift
//  FRAuthenticatorExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import FRAuthenticator

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var privacyScreen: UIImageView = UIImageView()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        // Handle deep links passed at cold launch
        for context in connectionOptions.urlContexts {
            handleDeepLink(url: context.url)
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let blurredImg = captureBlurredScreenshot()
        privacyScreen = UIImageView(image: blurredImg)
        window?.addSubview(privacyScreen)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        privacyScreen.removeFromSuperview()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handleDeepLink(url: context.url)
        }
    }

    // MARK: - Helpers

    private func handleDeepLink(url: URL) {
        NSLog("App opened with deeplink: \(url.absoluteString)")
        FRAClient.shared?.createMechanismFromUri(uri: url, onSuccess: { mechanism in
            NSLog("Successfully created a mechanism with deeplink: \(url.absoluteString)")
            DispatchQueue.main.async {
                if let rootViewController = self.window?.rootViewController as? UINavigationController,
                   let mainListViewCointroller = rootViewController.viewControllers.first as? MainListViewController {
                    mainListViewCointroller.reload()
                }
            }
        }, onError: { _ in
            NSLog("Error creating a mechanism with deeplink: \(url.absoluteString)")
        })
    }

    private func captureBlurredScreenshot() -> UIImage? {
        let size = window?.screen.bounds.size ?? CGSize()
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        window?.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let screenshotImg = image, let inputImage = CIImage(image: screenshotImg) else { return nil }
        let gaussianFilter = CIFilter(name: "CIBokehBlur")
        gaussianFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        gaussianFilter?.setValue(10, forKey: kCIInputRadiusKey)
        guard let outputImage = gaussianFilter?.outputImage else { return nil }
        return UIImage(ciImage: outputImage)
    }
}
