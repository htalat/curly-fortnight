import Foundation
import ApplicationServices

struct AXWindowInfo {
    let title: String
    let appName: String
    let pid: Int32
    let axElement: AXUIElement?
    
    var displayName: String {
        if title.isEmpty {
            return appName
        }
        return "\(appName) - \(title)"
    }
}