import Foundation
import UIKit
import AuthenticatorBluetooth

class AppSession: ProximityManagerDelegate {
    
    let proximityManager: ProximityManager = ProximiyManagerImpl.shared
    
    let notificationManager: NotificationManager = NotificationManagerImpl()
    
    init() {
        self.proximityManager.addDelegate(self)
    }
    
    deinit {
        self.proximityManager.removeDelegate(self)
    }
    
    func proximityManagerDidStartOperation(_ proximityManager: ProximityManager, proximiyOperation proximityOperation: ProximityOperation) {
        if UIApplication.shared.applicationState != .active {
            notificationManager.showProximityNotification(
                deviceId: proximityOperation.deviceId,
                title: "Bluetooth Authentication",
                message: proximityOperation.message ?? "")
        }
    }
    
    func proximityManagerDidFinishOperation(_ proximityManager: ProximityManager, proximityOperation: ProximityOperation) {
        notificationManager.removeProximityNotification(deviceId: proximityOperation.deviceId)
    }
    
}
