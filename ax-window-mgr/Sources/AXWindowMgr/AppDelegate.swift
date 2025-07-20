import AppKit
import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: NSStatusBar!
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var windowListController: AXWindowListViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createStatusBarItem()
        createPopover()
    }
    
    private func createStatusBarItem() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "macwindow.and.cursorarrow", accessibilityDescription: "AX Window Manager")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func createPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 450, height: 600)
        popover.behavior = .transient
        
        windowListController = AXWindowListViewController()
        popover.contentViewController = windowListController
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}