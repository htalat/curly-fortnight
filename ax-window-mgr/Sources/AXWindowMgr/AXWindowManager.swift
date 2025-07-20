import Foundation
import ApplicationServices
import AppKit

@MainActor
class AXWindowManager {
    
    static func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    static func requestAccessibilityPermissions() {
        // Open System Settings to Privacy & Security
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    static func getWindowsUsingAXAPI() -> [AXWindowInfo] {
        guard checkAccessibilityPermissions() else {
            requestAccessibilityPermissions()
            return []
        }
        
        var windows: [AXWindowInfo] = []
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Get windows using multiple approaches
        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let appName = app.localizedName,
                  !appName.isEmpty,
                  appName != "AXWindowMgr" else {
                continue
            }
            
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var foundWindows: [AXUIElement] = []
            
            // Method 1: Try standard windows attribute
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            
            if result == .success, let windowArray = windowsRef as? [AXUIElement] {
                foundWindows.append(contentsOf: windowArray)
            }
            
            // Method 2: Try getting all children and filter for windows
            var childrenRef: CFTypeRef?
            let childrenResult = AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &childrenRef)
            
            if childrenResult == .success, let children = childrenRef as? [AXUIElement] {
                for child in children {
                    var roleRef: CFTypeRef?
                    let roleResult = AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef)
                    
                    if roleResult == .success, let role = roleRef as? String, role == kAXWindowRole as String {
                        // This is a window, add it if not already found
                        let isAlreadyFound = foundWindows.contains { existingWindow in
                            return CFEqual(existingWindow, child)
                        }
                        if !isAlreadyFound {
                            foundWindows.append(child)
                        }
                    }
                }
            }
            
            // Method 3: Try to get minimized windows separately
            var minimizedRef: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(axApp, "AXMinimizedWindows" as CFString, &minimizedRef)
            
            if minimizedResult == .success, let minimizedWindows = minimizedRef as? [AXUIElement] {
                for minimizedWindow in minimizedWindows {
                    let isAlreadyFound = foundWindows.contains { existingWindow in
                        return CFEqual(existingWindow, minimizedWindow)
                    }
                    if !isAlreadyFound {
                        foundWindows.append(minimizedWindow)
                    }
                }
            }
            
            if !foundWindows.isEmpty {
                for window in foundWindows {
                    let windowInfo = getWindowInfo(from: window, appName: appName, pid: app.processIdentifier)
                    if let info = windowInfo {
                        windows.append(info)
                    }
                }
            } else {
                // Fallback: add app without specific window info
                let windowInfo = AXWindowInfo(
                    title: "",
                    appName: appName,
                    pid: app.processIdentifier,
                    axElement: nil
                )
                windows.append(windowInfo)
            }
        }
        
        return windows.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    private static func getWindowInfo(from window: AXUIElement, appName: String, pid: Int32) -> AXWindowInfo? {
        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        
        var title: String
        if titleResult == .success, let titleString = titleRef as? String {
            title = titleString
        } else {
            title = ""
        }
        
        var indicators: [String] = []
        
        // Check if window is minimized
        var minimizedRef: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
        
        if minimizedResult == .success, let isMinimized = minimizedRef as? Bool, isMinimized {
            indicators.append("Minimized")
        }
        
        // Check if window is visible (false = on different Space)
        var visibleRef: CFTypeRef?
        let visibleResult = AXUIElementCopyAttributeValue(window, "AXVisible" as CFString, &visibleRef)
        
        if visibleResult == .success, let isVisible = visibleRef as? Bool {
            if !isVisible {
                indicators.append("Other Space")
            }
        }
        
        // Check position for off-screen windows (another indicator of different Space)
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        
        if positionResult == .success, let position = positionRef as? CGPoint {
            // Unusual coordinates often indicate off-screen/different space
            if position.x < -10000 || position.y < -10000 || position.x > 20000 || position.y > 20000 {
                if !indicators.contains("Other Space") {
                    indicators.append("Off-screen")
                }
            }
        }
        
        // Add indicators to title
        if !indicators.isEmpty {
            let indicatorText = "(\(indicators.joined(separator: ", ")))"
            title = title.isEmpty ? indicatorText : "\(title) \(indicatorText)"
        }
        
        
        return AXWindowInfo(
            title: title,
            appName: appName,
            pid: pid,
            axElement: window
        )
    }
    
    static func focusWindow(_ windowInfo: AXWindowInfo) {
        if let axElement = windowInfo.axElement {
            // Try to raise the specific window
            AXUIElementPerformAction(axElement, kAXRaiseAction as CFString)
        }
        
        // Also activate the application
        let runningApp = NSRunningApplication(processIdentifier: windowInfo.pid)
        runningApp?.activate()
    }
}