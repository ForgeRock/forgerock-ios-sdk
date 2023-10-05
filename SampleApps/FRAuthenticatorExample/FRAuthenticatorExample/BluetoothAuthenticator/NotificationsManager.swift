import Foundation
import NotificationCenter

protocol NotificationManager: AnyObject {
    func showProximityNotification(deviceId: String, title: String, message: String)
    func removeProximityNotification(deviceId: String)
}

class NotificationManagerImpl: NSObject, NotificationManager, UNUserNotificationCenterDelegate {

    func showProximityNotification(deviceId: String, title: String, message: String) {
        Log.d("Showing proximity operation notification for device \(deviceId)")
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: deviceId, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
  
    func removeProximityNotification(deviceId: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [deviceId])
    }
    
}
