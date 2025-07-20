import AppKit
import Cocoa

@MainActor
class AXWindowListViewController: NSViewController {
    private var searchField: NSSearchField!
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var statusLabel: NSTextField!
    
    private var allWindows: [AXWindowInfo] = []
    private var filteredWindows: [AXWindowInfo] = []
    
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
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
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
        filteredWindows = allWindows
        
        if isViewLoaded {
            tableView.reloadData()
            searchField.stringValue = ""
        }
        
    }
    
    @objc private func requestPermissions() {
        AXWindowManager.requestAccessibilityPermissions()
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
        AXWindowManager.focusWindow(window)
        
        if let popover = view.window?.parent as? NSPopover {
            popover.performClose(nil)
        }
    }
}

extension AXWindowListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWindows.count
    }
}

extension AXWindowListViewController: NSTableViewDelegate {
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
            textField.lineBreakMode = .byTruncatingTail
            textField.cell?.truncatesLastVisibleLine = true
            textField.maximumNumberOfLines = 1
            textField.font = NSFont.systemFont(ofSize: 13)
            cellView.addSubview(textField)
            cellView.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                textField.heightAnchor.constraint(equalToConstant: 20)
            ])
        }
        
        let window = filteredWindows[row]
        let prefix = window.axElement != nil ? "🪟 " : "📱 "
        let displayText = prefix + window.displayName
        cellView.textField?.stringValue = displayText
        cellView.toolTip = displayText  // Show full text on hover
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 28
    }
}