import Foundation

struct ProximityOperation {
    var deviceId: String
    var state: State
    var message: String?
    var receivedAt: Date
    
    enum State {
        case pending, sendingApproved, sendingDenied, approved, denied, failed, cancelled
    }
}
