import AppKit
import Cocoa

@MainActor
class WindowListViewController: NSViewController {
    private var searchField: NSSearchField!
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    
    private var allWindows: [WindowInfo] = []
    private var filteredWindows: [WindowInfo] = []
    
    override func loadView() {
        view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        setupUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        refreshWindowList()
    }
    
    private func setupUI() {
        searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search windows..."
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)
        view.addSubview(searchField)
        
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)
        
        tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowSizeStyle = .medium
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WindowColumn"))
        column.title = "Windows"
        column.width = 380
        tableView.addTableColumn(column)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }
    
    func refreshWindowList() {
        allWindows = getOpenWindows()
        filteredWindows = allWindows
        
        if isViewLoaded {
            tableView.reloadData()
            searchField.stringValue = ""
        }
    }
    
    private func getOpenWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []
        
        // First try CG API for detailed window information
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for windowDict in windowList {
                guard let pid = windowDict[kCGWindowOwnerPID as String] as? Int32,
                      let windowNumber = windowDict[kCGWindowNumber as String] as? Int,
                      let ownerName = windowDict[kCGWindowOwnerName as String] as? String else {
                    continue
                }
                
                let windowName = windowDict[kCGWindowName as String] as? String ?? ""
                
                if ownerName == "WinMgr" || ownerName == "Window Server" || ownerName == "Dock" {
                    continue
                }
                
                let windowInfo = WindowInfo(
                    title: windowName,
                    appName: ownerName,
                    windowNumber: windowNumber,
                    pid: pid
                )
                
                windows.append(windowInfo)
            }
        }
        
        // Add running apps that don't expose their windows through CG API
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let appName = app.localizedName,
                  !appName.isEmpty,
                  appName != "WinMgr" else {
                continue
            }
            
            // Check if we already have windows for this app from CG API
            let hasExistingWindows = windows.contains { $0.pid == app.processIdentifier }
            
            if !hasExistingWindows && !app.isHidden {
                let windowInfo = WindowInfo(
                    title: "",
                    appName: appName,
                    windowNumber: 0,
                    pid: app.processIdentifier
                )
                windows.append(windowInfo)
            }
        }
        
        return windows.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    @objc private func searchFieldChanged() {
        let searchText = searchField.stringValue.lowercased()
        
        if searchText.isEmpty {
            filteredWindows = allWindows
        } else {
            filteredWindows = allWindows.filter { window in
                window.displayName.lowercased().contains(searchText)
            }
        }
        
        tableView.reloadData()
    }
    
    @objc private func tableViewDoubleClick() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 && selectedRow < filteredWindows.count else { return }
        
        let window = filteredWindows[selectedRow]
        focusWindow(window)
    }
    
    private func focusWindow(_ windowInfo: WindowInfo) {
        let runningApp = NSRunningApplication(processIdentifier: windowInfo.pid)
        runningApp?.activate()
        
        if let popover = view.window?.parent as? NSPopover {
            popover.performClose(nil)
        }
    }
}

extension WindowListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWindows.count
    }
}

extension WindowListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("WindowCellView")
        
        let cellView: NSTableCellView
        if let reusedView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            cellView = reusedView
        } else {
            cellView = NSTableCellView()
            cellView.identifier = identifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isSelectable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            cellView.addSubview(textField)
            cellView.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])
        }
        
        let window = filteredWindows[row]
        cellView.textField?.stringValue = window.displayName
        
        return cellView
    }
}