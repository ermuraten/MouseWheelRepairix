import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var mouseHook: MouseHook!
    
    // Selected time tag mapping
    let timeIntervals: [Int: TimeInterval] = [
        1: 0.05, // 50ms
        2: 0.10, // 100ms
        3: 0.20  // 200ms
    ]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Load user's custom icon with alpha transparency
            let resourcePath = Bundle.main.path(forResource: "mouse_icon", ofType: "png")
            if let path = resourcePath, let image = NSImage(contentsOfFile: path) {
                image.isTemplate = true // Makes it adapt to dark/light mode
                button.image = image
            } else {
                // Fallback
                button.title = "🖱"
            }
        }
        
        setupMenu()
        
        // Check permissions
        checkAccessibilityPermissions()
        
        // Initialize and start hook
        mouseHook = MouseHook()
        mouseHook.start()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "MouseWheel Repairix", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "Status: Active", action: #selector(toggleActive(_:)), keyEquivalent: "")
        toggleItem.state = .on
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let debounceMenu = NSMenu()
        let debounceItem = NSMenuItem(title: "Debounce Time", action: nil, keyEquivalent: "")
        debounceItem.submenu = debounceMenu
        menu.addItem(debounceItem)
        
        // 50ms
        let item50 = NSMenuItem(title: "50 ms", action: #selector(setDebounceTime(_:)), keyEquivalent: "")
        item50.tag = 1
        debounceMenu.addItem(item50)
        
        // 100ms (Default)
        let item100 = NSMenuItem(title: "100 ms", action: #selector(setDebounceTime(_:)), keyEquivalent: "")
        item100.tag = 2
        item100.state = .on
        debounceMenu.addItem(item100)
        
        // 200ms
        let item200 = NSMenuItem(title: "200 ms", action: #selector(setDebounceTime(_:)), keyEquivalent: "")
        item200.tag = 3
        debounceMenu.addItem(item200)
        
        debounceMenu.addItem(NSMenuItem.separator())
        
        // Custom
        let itemCustom = NSMenuItem(title: "Custom...", action: #selector(promptForCustomTime(_:)), keyEquivalent: "")
        itemCustom.tag = 99
        debounceMenu.addItem(itemCustom)
        
        menu.addItem(NSMenuItem.separator())
        
        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
        // Default to off for now to prevent launch crash due to AppleScript blocking/failing
        loginItem.state = .off 
        menu.addItem(loginItem)
        
        // Asynchronously check status to update UI later? 
        // For now, let's keep it simple. If the user toggles it, we seek permission then.
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        self.statusItem.menu = menu
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    @objc func toggleActive(_ sender: NSMenuItem) {
        if sender.state == .on {
            mouseHook.stop()
            sender.state = .off
            sender.title = "Status: Inactive"
        } else {
            mouseHook.start()
            sender.state = .on
            sender.title = "Status: Active"
        }
    }
    
    @objc func setDebounceTime(_ sender: NSMenuItem) {
        // Uncheck all siblings
        if let parentInfo = sender.parent {
            for item in parentInfo.submenu?.items ?? [] {
                item.state = .off
            }
        }
        
        sender.state = .on
        
        if let interval = timeIntervals[sender.tag] {
            mouseHook.debounceInterval = interval
            print("Debounce set to \(interval)s")
        }
    }
    
    @objc func promptForCustomTime(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Custom Debounce Time"
        alert.informativeText = "Enter debounce time in milliseconds:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "e.g. 125"
        alert.accessoryView = input
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let ms = Int(input.stringValue), ms > 0 {
                let seconds = Double(ms) / 1000.0
                mouseHook.debounceInterval = seconds
                print("Custom debounce set to \(seconds)s")
                
                // Update Menu State
                 if let parentInfo = sender.parent {
                    for item in parentInfo.submenu?.items ?? [] {
                        item.state = .off
                    }
                }
                sender.state = .on
                sender.title = "Custom (\(ms) ms)"
            }
        }
    }
    
    // MARK: - Start at Login Logic
    
    // MARK: - Start at Login Logic (LaunchAgents)
    
    @objc func toggleStartAtLogin(_ sender: NSMenuItem) {
        let newState = (sender.state == .off)
        if setAppLoginItem(enabled: newState) {
            sender.state = newState ? .on : .off
        } else {
             // Show error if file write fails, though rare
             let alert = NSAlert()
             alert.messageText = "Error"
             alert.informativeText = "Could not create/delete LaunchAgent plist."
             alert.runModal()
        }
    }
    
    private var launchAgentURL: URL? {
        let fileManager = FileManager.default
        guard let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return nil }
        let launchAgentsURL = libraryURL.appendingPathComponent("LaunchAgents")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true, attributes: nil)
        
        return launchAgentsURL.appendingPathComponent("com.murat.MouseWheelRepairix.plist")
    }

    private func isAppLoginItem() -> Bool {
        guard let url = launchAgentURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func setAppLoginItem(enabled: Bool) -> Bool {
        guard let url = launchAgentURL else { return false }
        let fileManager = FileManager.default
        
        if enabled {
            let appPath = Bundle.main.bundlePath
            // Escape xml properly if needed, but path usually simple. 
            // Better to use proper plist serialization
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.murat.MouseWheelRepairix</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(appPath)/Contents/MacOS/MouseWheelRepairix</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>ProcessType</key>
                <string>Interactive</string>
            </dict>
            </plist>
            """
            
            do {
                try plistContent.write(to: url, atomically: true, encoding: .utf8)
                return true
            } catch {
                print("Failed to write LaunchAgent: \(error)")
                return false
            }
        } else {
            do {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                }
                return true
            } catch {
                print("Failed to remove LaunchAgent: \(error)")
                return false
            }
        }
    }
}
