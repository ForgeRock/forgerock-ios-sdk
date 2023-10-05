import Foundation

struct ProximityData {
    let agent: String
    let deviceId: String
    let workstationId: String
    let publicKey: String
    let password: String
    let username: String
    
    static func from(token: String) -> ProximityData {
        let data = Data(base64Encoded: token)
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any]
            let agent = json["agent"] as! String
            let deviceId = json["name"] as! String
            let workstationId = json["workstationId"] as! String
            let publicKey = json["key"] as! String
            let password = json["password"] as! String
            let username = json["username"] as! String
            return ProximityData(agent: agent, deviceId: deviceId, workstationId: workstationId, publicKey: publicKey, password: password, username: username)
        } catch {
            fatalError("Unable to parse SDO token, Did you forgot to set your SDO token at 'SDOTokenHandler.swift'")
        }
    }
}
