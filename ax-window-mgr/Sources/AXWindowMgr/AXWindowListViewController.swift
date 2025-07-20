import AppKit
import Cocoa

@MainActor
class AXWindowListViewController: NSViewController {
    private var searchField: NSSearchField!
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var statusLabel: NSTextField!
    
    private var allWindows: [AXWindowInfo] = []
    private var appGroups: [AXAppGroup] = []
    
    override func loadView() {
        view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 450, height: 600)
        setupUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        refreshWindowList()
    }
    
    private func setupUI() {
        // Status label for permissions
        statusLabel = NSTextField()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.isEditable = false
        statusLabel.isSelectable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = .clear
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.stringValue = "Checking accessibility permissions..."
        view.addSubview(statusLabel)
        
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
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = []
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WindowColumn"))
        column.title = "Windows"
        column.width = 430
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            searchField.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
    
    func refreshWindowList() {
        if AXWindowManager.checkAccessibilityPermissions() {
            statusLabel.stringValue = "AX API Access: ✅ Granted"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.stringValue = "AX API Access: ❌ Not granted - Click to request"
            statusLabel.textColor = .systemRed
            statusLabel.isSelectable = true
            
            // Make status label clickable
            let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(requestPermissions))
            statusLabel.addGestureRecognizer(clickGesture)
        }
        
        allWindows = AXWindowManager.getWindowsUsingAXAPI()
        updateAppGroups()
        
        if isViewLoaded {
            tableView.reloadData()
            searchField.stringValue = ""
        }
    }
    
    private func updateAppGroups() {
        let searchText = searchField?.stringValue.lowercased() ?? ""
        
        let filteredWindows = searchText.isEmpty ? allWindows : allWindows.filter { window in
            window.displayName.lowercased().contains(searchText)
        }
        
        let groupedByApp = Dictionary(grouping: filteredWindows) { $0.appName }
        
        appGroups = groupedByApp.map { appName, windows in
            AXAppGroup(appName: appName, windows: windows.sorted { $0.title < $1.title })
        }.sorted { $0.appName.localizedCaseInsensitiveCompare($1.appName) == .orderedAscending }
    }
    
    @objc private func requestPermissions() {
        AXWindowManager.requestAccessibilityPermissions()
    }
    
    @objc private func searchFieldChanged() {
        updateAppGroups()
        tableView.reloadData()
    }
    
    @objc private func tableViewDoubleClick() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let (groupIndex, windowIndex) = indexPathForRow(selectedRow)
        guard groupIndex < appGroups.count else { return }
        
        let group = appGroups[groupIndex]
        if windowIndex == -1 {
            // Header row - focus the app
            if let window = group.windows.first {
                AXWindowManager.focusWindow(window)
            }
        } else if windowIndex < group.windows.count {
            // Window row
            let window = group.windows[windowIndex]
            AXWindowManager.focusWindow(window)
        }
        
        if let popover = view.window?.parent as? NSPopover {
            popover.performClose(nil)
        }
    }
    
    private func indexPathForRow(_ row: Int) -> (groupIndex: Int, windowIndex: Int) {
        var currentRow = 0
        
        for (groupIndex, group) in appGroups.enumerated() {
            // Header row
            if currentRow == row {
                return (groupIndex, -1)
            }
            currentRow += 1
            
            // Window rows
            for windowIndex in 0..<group.windows.count {
                if currentRow == row {
                    return (groupIndex, windowIndex)
                }
                currentRow += 1
            }
        }
        
        return (-1, -1)
    }
}

extension AXWindowListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return appGroups.reduce(0) { total, group in
            total + 1 + group.windows.count  // 1 for header + windows
        }
    }
}

extension AXWindowListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let (groupIndex, windowIndex) = indexPathForRow(row)
        guard groupIndex < appGroups.count else { return nil }
        
        let group = appGroups[groupIndex]
        
        if windowIndex == -1 {
            // Header row
            let identifier = NSUserInterfaceItemIdentifier("HeaderCellView")
            
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
                textField.lineBreakMode = .byTruncatingTail
                textField.cell?.truncatesLastVisibleLine = true
                textField.maximumNumberOfLines = 1
                textField.font = NSFont.boldSystemFont(ofSize: 13)
                textField.textColor = .labelColor
                cellView.addSubview(textField)
                cellView.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 0),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                    textField.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
            
            let displayText = group.appName + group.displayCount
            cellView.textField?.stringValue = displayText
            cellView.toolTip = displayText
            
            return cellView
        } else {
            // Window row
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
                textField.lineBreakMode = .byTruncatingTail
                textField.cell?.truncatesLastVisibleLine = true
                textField.maximumNumberOfLines = 1
                textField.font = NSFont.systemFont(ofSize: 13)
                textField.textColor = .secondaryLabelColor
                cellView.addSubview(textField)
                cellView.textField = textField
                
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 16),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                    textField.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
            
            let window = group.windows[windowIndex]
            let displayText = window.title.isEmpty ? "(No title)" : window.title
            cellView.textField?.stringValue = displayText
            cellView.toolTip = window.displayName
            
            return cellView
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 28
    }
}