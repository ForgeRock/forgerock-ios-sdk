import Foundation
import AuthenticatorBluetooth

protocol ProximityManager {
    func approveAuth()
    func denyAuth()
    func addDelegate(_ delegate: ProximityManagerDelegate)
    func removeDelegate(_ delegate: ProximityManagerDelegate)
}

protocol ProximityManagerDelegate: AnyObject {
    func proximityManagerDidStartOperation(_ proximityManager: ProximityManager, proximiyOperation: ProximityOperation)
    func proximityManagerDidFinishOperation(_ proximityManager: ProximityManager, proximityOperation: ProximityOperation)
    func onProximityOperationsUpdate(_ proximityManager: ProximityManager, proximityOperations: [ProximityOperation])
}

extension ProximityManagerDelegate {
    func proximityManagerDidStartOperation(_ proximityManager: ProximityManager, proximiyOperation: ProximityOperation){}
    func proximityManagerDidFinishOperation(_ proximityManager: ProximityManager, proximityOperation: ProximityOperation){}
    func onProximityOperationsUpdate(_ proximityManager: ProximityManager, proximityOperations: [ProximityOperation]){}
}

class ProximiyManagerImpl: ProximityManager, BluetoothManagerDelegate {

    public static let shared: ProximityManager = {
        let instance = ProximiyManagerImpl(
            bluetoothManager: BluetoothAuthenticator.shared.bluetoothManager,
            sdoTokenHandler: SDOTokenHandler()
        )
        return instance
    }()
    
    private let delegates = DelegateCollection<ProximityManagerDelegate>()
    
    let bluetoothManager: BluetoothManager
        
    let proximityData: ProximityData
    
    var proximityOperations: [ProximityOperation] = []
        
    private init(bluetoothManager: BluetoothManager, sdoTokenHandler: SDOTokenHandler) {
        self.proximityData = ProximityData.from(token: sdoTokenHandler.token)
        self.bluetoothManager = bluetoothManager
        self.bluetoothManager.delegate = self
    }
        
    func addDelegate(_ delegate: ProximityManagerDelegate) {
        delegates.add(delegate)
        delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }
    }
    
    func removeDelegate(_ delegate: ProximityManagerDelegate) {
        delegates.remove(delegate)
    }
   
    func approveAuth() {
        if let index = proximityOperations.firstIndex(where: { $0.deviceId == proximityData.deviceId }) {
            proximityOperations[index].state = .sendingApproved
            delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }

            bluetoothManager.approveV2(deviceId: proximityData.deviceId, publicKey: proximityData.publicKey, encryptedPasswords: [proximityData.password])
        }
    }
    
    func denyAuth() {
        if let index = proximityOperations.firstIndex(where: { $0.deviceId == proximityData.deviceId }) {
            proximityOperations[index].state = .sendingDenied
            delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }

            bluetoothManager.deny(deviceId: proximityData.deviceId, publicKey: proximityData.publicKey)
        }
    }
    
    func deviceIdsForBluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager) -> [String] {
        return [proximityData.deviceId]
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didDiscoverDeviceWithId deviceId: String) {
        Log.d("didDiscoverDeviceWithId \(deviceId)")
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, shouldConnectToDeviceWithId deviceId: String) -> Bool {
        Log.d("shouldConnectToDeviceWithId \(deviceId)")
        
        return true
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didRequestAuthenticationForDeviceWithId deviceId: String, message: String?) {
        Log.d("didRequestAuthenticationForDeviceWithId \(deviceId), message: \(String(describing: message))")
        
        guard proximityOperations.firstIndex(where: { $0.deviceId == deviceId }) == nil else {
            Log.d("Device \(deviceId) already started authentication request")
            return
        }
            
        let proximityOperation = ProximityOperation(deviceId: deviceId, state: .pending, message: message, receivedAt: Date())
        proximityOperations.append(proximityOperation)
        
        delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }
        delegates.notify { $0.proximityManagerDidStartOperation(self, proximiyOperation: proximityOperation) }
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didSendAuthenticationToDeviceWithId deviceId: String) {
        Log.d("didSendAuthenticationToDeviceWithId \(deviceId)")
        
        if let index = proximityOperations.firstIndex(where: { $0.deviceId == deviceId }) {
            proximityOperations[index].state = proximityOperations[index].state == .sendingApproved ? .approved : .denied
            delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }
            delegates.notify { $0.proximityManagerDidFinishOperation(self, proximityOperation: proximityOperations[index]) }
        }
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didFinishConnectionToDeviceWithId deviceId: String) {
        Log.d("didFinishConnectionToDeviceWithId \(deviceId)")
        
        if let index = proximityOperations.firstIndex(where: { $0.deviceId == deviceId }) {
            delegates.notify { $0.proximityManagerDidFinishOperation(self, proximityOperation: proximityOperations[index]) }
        }
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didFailConnectionToDeviceWithId deviceId: String) {
        Log.d("didFailConnectionToDeviceWithId \(deviceId)")
        
        if let index = proximityOperations.firstIndex(where: { $0.deviceId == deviceId }) {
            proximityOperations[index].state = .failed
        }
        delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: proximityOperations) }
    }
    
    func bluetoothManager(_ manager: AuthenticatorBluetooth.BluetoothManager, didDisconnectFromDeviceWithId deviceId: String) {
        Log.d("didDisconnectFromDeviceWithId \(deviceId)")
        
        // Wait half a second before removing the authentication request for a better user experience
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.proximityOperations = self.proximityOperations.filter { $0.deviceId != deviceId }
            self.delegates.notify { $0.onProximityOperationsUpdate(self, proximityOperations: self.proximityOperations) }
        }
    }
    
}
