import Foundation

struct AppGroup {
    let appName: String
    let windows: [WindowInfo]
    
    var displayCount: String {
        return windows.count == 1 ? "" : " (\(windows.count))"
    }
}