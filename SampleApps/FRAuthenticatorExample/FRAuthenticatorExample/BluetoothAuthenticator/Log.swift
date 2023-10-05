import OSLog

class Log {
    
    private static let subsystem = Bundle.main.bundleIdentifier!
    private static let category = "App"
    
    static let logger = OSLog(subsystem: subsystem, category: category)
    
    static func d(_ message: String) {
        os_log("%{public}@", log: logger, type: .debug, message)
    }
    
}
