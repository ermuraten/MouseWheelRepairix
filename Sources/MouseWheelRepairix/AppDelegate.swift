import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var mouseHook: MouseHook!
    
    // Measurement window
    var measurementWindow: NSWindow?
    var intervalTextView: NSTextView?
    var clickIntervals: [Double] = []
    let maxIntervals = 10
    
    // Selected time tag mapping
    let timeIntervals: [Int: TimeInterval] = [
        1: 0.05, // 50ms
        2: 0.10, // 100ms
        3: 0.20  // 200ms
    ]
    
    // UserDefaults keys
    private let debounceTimeKey = "savedDebounceTime"
    private let defaultDebounceMs = 100.0 // Default 100ms

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // Load colored mouse icon with red scroll wheel
            let resourcePath = Bundle.main.path(forResource: "mouse_icon", ofType: "png")
            if let path = resourcePath, let image = NSImage(contentsOfFile: path) {
                // Use colored icon (not template) to show red scroll wheel
                image.isTemplate = false
                image.size = NSSize(width: 18, height: 18)
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
        mouseHook.clickIntervalCallback = { [weak self] intervalMs in
            self?.handleClickInterval(intervalMs)
        }
        
        // Load saved debounce time
        loadSavedDebounceTime()
        
        mouseHook.start()
    }
    
    func loadSavedDebounceTime() {
        var savedMs: Double = 0
        
        if let settingsURL = getSettingsFileURL(),
           let data = try? Data(contentsOf: settingsURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let ms = plist[debounceTimeKey] as? Double, ms > 0 {
            savedMs = ms
            let seconds = ms / 1000.0
            mouseHook.debounceInterval = seconds
            print("Loaded saved debounce time: \(ms)ms from \(settingsURL.path)")
        } else {
            // Set default
            savedMs = defaultDebounceMs
            mouseHook.debounceInterval = defaultDebounceMs / 1000.0
            print("Using default debounce time: \(defaultDebounceMs)ms")
        }
        
        // Update menu to reflect saved setting
        updateMenuForSavedDebounceTime(savedMs)
    }
    
    func updateMenuForSavedDebounceTime(_ ms: Double) {
        guard let menu = statusItem.menu else { return }
        
        // Find debounce submenu
        for item in menu.items {
            if let submenu = item.submenu {
                // Uncheck all items first
                for subItem in submenu.items {
                    subItem.state = .off
                }
                
                // Check the matching item
                let seconds = ms / 1000.0
                var foundMatch = false
                
                for subItem in submenu.items {
                    if let interval = timeIntervals[subItem.tag], interval == seconds {
                        subItem.state = .on
                        foundMatch = true
                        break
                    }
                }
                
                // If no preset matches, mark Custom
                if !foundMatch {
                    for subItem in submenu.items where subItem.tag == 99 {
                        subItem.state = .on
                        subItem.title = "Custom (\(Int(ms)) ms)"
                        break
                    }
                }
            }
        }
    }
    
    func saveDebounceTime(_ ms: Double) {
        guard let settingsURL = getSettingsFileURL() else {
            print("ERROR: Could not get settings file URL")
            return
        }
        
        let settings: [String: Any] = [debounceTimeKey: ms]
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: settings, format: .xml, options: 0)
            try data.write(to: settingsURL)
            print("Saved debounce time: \(ms)ms to \(settingsURL.path)")
        } catch {
            print("ERROR saving settings: \(error)")
        }
    }
    
    func getSettingsFileURL() -> URL? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let appFolder = appSupportURL.appendingPathComponent("MouseWheelRepairix")
        
        // Create folder if needed
        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appFolder.appendingPathComponent("settings.plist")
    }
    
    func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "MouseWheel Repairix \(AppVersion.versionString)", action: nil, keyEquivalent: ""))
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
        
        let measurementItem = NSMenuItem(title: "Measure Click Intervals", action: #selector(toggleMeasurement(_:)), keyEquivalent: "")
        measurementItem.state = .off
        menu.addItem(measurementItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About MouseWheel Repairix", action: #selector(showAbout(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        self.statusItem.menu = menu
    }
    
    func checkAccessibilityPermissions() {
        // Check if we already have permissions (without prompting)
        let trusted = AXIsProcessTrusted()
        
        if trusted {
            print("Accessibility permissions already granted")
            return
        }
        
        // Show our own dialog first explaining what will happen
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MouseWheelRepairix needs Accessibility permissions to detect and fix mouse wheel double-clicks.\n\nAfter granting permission in System Settings, you'll need to restart the app for it to work."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility
            let prefURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(prefURL)
            
            // Start monitoring for permission grant
            monitorForPermissionGrant()
        }
    }
    
    func monitorForPermissionGrant() {
        // Check every 2 seconds if permission was granted
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                
                DispatchQueue.main.async {
                    self?.showRestartRequiredDialog()
                }
            }
        }
    }
    
    func showRestartRequiredDialog() {
        let alert = NSAlert()
        alert.messageText = "Restart Required"
        alert.informativeText = "Thank you! Accessibility permission was granted.\n\nPlease restart the app for the changes to take effect."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Restart the app
            restartApp()
        }
    }
    
    func restartApp() {
        let bundlePath = Bundle.main.bundlePath
        
        // Use shell command to relaunch after a short delay
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(bundlePath)\""]
        
        do {
            try task.run()
            // Terminate current instance
            NSApp.terminate(nil)
        } catch {
            print("Failed to restart: \(error)")
        }
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
            saveDebounceTime(interval * 1000.0) // Save in ms
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
                saveDebounceTime(Double(ms)) // Save in ms
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
    
    // MARK: - About Dialog
    
    @objc func showAbout(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "MouseWheel Repairix \(AppVersion.versionString)"
        alert.informativeText = """
        A macOS utility to fix erratic mouse wheel scrolling behavior through intelligent debouncing.
        
        \(AppVersion.fullVersionString)
        
        Features:
        • Configurable debounce times (50ms, 100ms, 200ms, custom)
        • Menu bar integration with status control
        • Start at login support
        • Dark/light mode adaptive icon
        
        See CHANGELOG.md for full release notes.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Measurement Mode
    
    @objc func toggleMeasurement(_ sender: NSMenuItem) {
        if sender.state == .off {
            // Enable measurement mode
            mouseHook.measurementMode = true
            sender.state = .on
            sender.title = "Measure Click Intervals ✓"
            showMeasurementWindow()
        } else {
            // Disable measurement mode
            mouseHook.measurementMode = false
            sender.state = .off
            sender.title = "Measure Click Intervals"
            hideMeasurementWindow()
        }
    }
    
    func showMeasurementWindow() {
        // Create window fresh each time (previous window was closed/deallocated)
        if measurementWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 450),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Click Interval Meter"
            window.center()
            window.delegate = self
            window.isReleasedWhenClosed = false
            
            // Main content view with dark theme
            let contentView = NSView(frame: window.contentView!.bounds)
            contentView.autoresizingMask = [.width, .height]
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).cgColor
            
            // App icon at top
            let iconView = NSImageView(frame: NSRect(x: 140, y: 375, width: 100, height: 60))
            if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
               let iconImage = NSImage(contentsOfFile: iconPath) {
                iconView.image = iconImage
            } else if let iconPath = Bundle.main.path(forResource: "mouse_icon", ofType: "png"),
                      let iconImage = NSImage(contentsOfFile: iconPath) {
                iconView.image = iconImage
            }
            iconView.imageScaling = .scaleProportionallyUpOrDown
            contentView.addSubview(iconView)
            
            // Title
            let titleLabel = NSTextField(labelWithString: "Wheel Click Meter")
            titleLabel.frame = NSRect(x: 0, y: 350, width: 380, height: 30)
            titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = .white
            titleLabel.alignment = .center
            titleLabel.isBordered = false
            titleLabel.backgroundColor = .clear
            contentView.addSubview(titleLabel)
            
            // Subtitle
            let subtitleLabel = NSTextField(labelWithString: "Press the mouse wheel button")
            subtitleLabel.frame = NSRect(x: 0, y: 328, width: 380, height: 20)
            subtitleLabel.font = NSFont.systemFont(ofSize: 12)
            subtitleLabel.textColor = NSColor(calibratedRed: 0.6, green: 0.6, blue: 0.65, alpha: 1.0)
            subtitleLabel.alignment = .center
            subtitleLabel.isBordered = false
            subtitleLabel.backgroundColor = .clear
            contentView.addSubview(subtitleLabel)
            
            // Card for intervals
            let cardView = NSView(frame: NSRect(x: 20, y: 100, width: 340, height: 220))
            cardView.wantsLayer = true
            cardView.layer?.backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.2, alpha: 1.0).cgColor
            cardView.layer?.cornerRadius = 12
            contentView.addSubview(cardView)
            
            // ScrollView inside card
            let scrollView = NSScrollView(frame: NSRect(x: 10, y: 10, width: 320, height: 200))
            scrollView.hasVerticalScroller = true
            scrollView.borderType = .noBorder
            scrollView.backgroundColor = .clear
            scrollView.drawsBackground = false
            
            let textView = NSTextView(frame: scrollView.bounds)
            textView.isEditable = false
            textView.isSelectable = true
            textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
            textView.textContainerInset = NSSize(width: 10, height: 10)
            textView.backgroundColor = .clear
            textView.textColor = .white
            textView.drawsBackground = false
            scrollView.documentView = textView
            cardView.addSubview(scrollView)
            
            self.intervalTextView = textView
            
            // Average display
            let avgLabel = NSTextField(labelWithString: "Average: -- ms")
            avgLabel.frame = NSRect(x: 0, y: 60, width: 380, height: 30)
            avgLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
            avgLabel.textColor = NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.6, alpha: 1.0)
            avgLabel.alignment = .center
            avgLabel.isBordered = false
            avgLabel.backgroundColor = .clear
            avgLabel.tag = 999
            contentView.addSubview(avgLabel)
            
            // Clear button
            let clearButton = NSButton(frame: NSRect(x: 130, y: 15, width: 120, height: 35))
            clearButton.title = "Clear"
            clearButton.bezelStyle = .rounded
            clearButton.target = self
            clearButton.action = #selector(clearMeasurements(_:))
            clearButton.wantsLayer = true
            contentView.addSubview(clearButton)
            
            window.contentView = contentView
            measurementWindow = window
        }
        
        // Reset measurements
        clickIntervals.removeAll()
        updateMeasurementDisplay()
        
        // Ensure window is visible and active
        measurementWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideMeasurementWindow() {
        measurementWindow?.orderOut(nil)
    }
    
    func handleClickInterval(_ intervalMs: Double) {
        clickIntervals.append(intervalMs)
        if clickIntervals.count > maxIntervals {
            clickIntervals.removeFirst()
        }
        updateMeasurementDisplay()
    }
    
    func updateMeasurementDisplay() {
        guard let textView = intervalTextView else { return }
        
        var text = ""
        for (index, interval) in clickIntervals.enumerated() {
            text += String(format: "%2d. %6.1f ms\n", index + 1, interval)
        }
        
        if text.isEmpty {
            text = "Waiting for wheel clicks...\n\nClick the mouse wheel button to measure intervals."
        }
        
        textView.string = text
        
        // Update average
        if let avgLabel = measurementWindow?.contentView?.viewWithTag(999) as? NSTextField {
            if clickIntervals.isEmpty {
                avgLabel.stringValue = "Average: -- ms"
            } else {
                let avg = clickIntervals.reduce(0, +) / Double(clickIntervals.count)
                avgLabel.stringValue = String(format: "Average: %.1f ms", avg)
            }
        }
    }
    
    @objc func clearMeasurements(_ sender: Any) {
        clickIntervals.removeAll()
        updateMeasurementDisplay()
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == measurementWindow {
            // Turn off measurement mode
            if let menu = statusItem.menu {
                for item in menu.items {
                    if item.action == #selector(toggleMeasurement(_:)) {
                        item.state = .off
                        item.title = "Measure Click Intervals"
                        mouseHook.measurementMode = false
                        break
                    }
                }
            }
            // Clear the reference so a fresh window is created next time
            intervalTextView = nil
            measurementWindow = nil
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender == measurementWindow {
            // Allow closing via X button
            return true
        }
        return true
    }
}
