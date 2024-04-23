//
// Copyright (c) 2022 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import UIKit
import PingProtect

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window?.makeKeyAndVisible()

      let initParams = PIInitParams(envId: "02fb4743-189a-4bc7-9d6c-a919edfe6447",
                                          deviceAttributesToIgnore: [],
                                          consoleLogEnabled: true,
                                          customHost: "",
                                          lazyMetadata: false,
                                          behavioralDataCollection: true)
            PIProtect.start(initParams: initParams) { error in
                if let error = error as? NSError {
                  print("Ping Protect Init Error \(error.localizedDescription)")
                } else {
                  print("Ping Protect Init Success")
                }
            }

        return true
    }
    
}

