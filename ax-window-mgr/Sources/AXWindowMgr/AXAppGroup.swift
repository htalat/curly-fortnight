import Foundation

struct AXAppGroup {
    let appName: String
    let windows: [AXWindowInfo]
    
    var displayCount: String {
        return windows.count == 1 ? "" : " (\(windows.count))"
    }
}