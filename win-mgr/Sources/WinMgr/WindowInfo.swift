import AppKit

struct WindowInfo {
    let title: String
    let appName: String
    let windowNumber: Int
    let pid: Int32
    
    var displayName: String {
        if title.isEmpty {
            return appName
        }
        return "\(appName) - \(title)"
    }
}