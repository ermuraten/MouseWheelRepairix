import Foundation

struct AppVersion {
    static let version = "1.1.0"
    static let buildNumber = "2"
    
    static var versionString: String {
        return "v\(version)"
    }
    
    static var fullVersionString: String {
        return "Version \(version) (Build \(buildNumber))"
    }
}
