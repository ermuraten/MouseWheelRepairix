import Cocoa

class PopoverViewController: NSViewController {
    
    // MARK: - Properties
    weak var appDelegate: AppDelegate?
    
    // Views
    private var mainView: NSView!
    private var measureView: NSView!
    private var aboutView: NSView!
    private var containerView: NSView!
    
    // Main view controls
    private var statusToggle: NSSwitch!
    private var statusDot: NSView!
    private var statusTextLabel: NSTextField!
    private var debounceSlider: NSSlider!
    private var debounceLabel: NSTextField!
    private var blockedCountLabel: NSTextField!
    private var lastIntervalLabel: NSTextField!
    
    // Measurement view controls
    private var measureIntervalLabel: NSTextField!
    private var measureHistoryView: NSStackView!
    private var emptyStateLabel: NSTextField!
    private var clickIntervals: [Double] = []
    private let maxIntervals = 8
    
    private var isShowingMeasure = false
    private var isShowingAbout = false
    
    // MARK: - Lifecycle
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 440))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.wantsLayer = true
        
        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            NSColor(red: 0.29, green: 0.10, blue: 0.42, alpha: 1.0).cgColor,
            NSColor(red: 0.20, green: 0.15, blue: 0.45, alpha: 1.0).cgColor,
            NSColor(red: 0.10, green: 0.23, blue: 0.42, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer?.insertSublayer(gradientLayer, at: 0)
        
        // Container for animated views
        containerView = NSView(frame: view.bounds)
        containerView.wantsLayer = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Create all views
        mainView = createMainView()
        measureView = createMeasureView()
        aboutView = createAboutView()
        
        // Start with main view
        containerView.addSubview(mainView)
        mainView.frame = containerView.bounds
    }
    
    // MARK: - Main View
    
    private func createMainView() -> NSView {
        let container = NSView(frame: view.bounds)
        container.wantsLayer = true
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 12
        mainStack.edgeInsets = NSEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        mainStack.addArrangedSubview(createHeader())
        mainStack.addArrangedSubview(createCardsGrid())
        mainStack.addArrangedSubview(createSliderCard())
        mainStack.addArrangedSubview(createActionButtons())
        mainStack.addArrangedSubview(createFooter())
        
        return container
    }
    
    // MARK: - Measurement View
    
    private func createMeasureView() -> NSView {
        let container = NSView(frame: view.bounds)
        container.wantsLayer = true
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mainStack)
        
        // Use constraint-based padding with 20px margins
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        // Header with back button
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        
        let backBtn = NSButton(title: "← Back", target: self, action: #selector(backToMain(_:)))
        backBtn.bezelStyle = .inline
        backBtn.isBordered = false
        backBtn.contentTintColor = .white
        
        let titleLabel = NSTextField(labelWithString: "Click Measurement")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        
        headerStack.addArrangedSubview(backBtn)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(NSView()) // Spacer
        mainStack.addArrangedSubview(headerStack)
        
        // Instructions
        let instructionLabel = NSTextField(wrappingLabelWithString: "Click the middle mouse button repeatedly to measure the interval between clicks.")
        instructionLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        instructionLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        mainStack.addArrangedSubview(instructionLabel)
        
        // Big interval display
        let intervalCard = createCard()
        let intervalStack = NSStackView()
        intervalStack.orientation = .vertical
        intervalStack.alignment = .centerX
        intervalStack.spacing = 4
        intervalStack.translatesAutoresizingMaskIntoConstraints = false
        intervalCard.addSubview(intervalStack)
        
        NSLayoutConstraint.activate([
            intervalStack.centerXAnchor.constraint(equalTo: intervalCard.centerXAnchor),
            intervalStack.centerYAnchor.constraint(equalTo: intervalCard.centerYAnchor)
        ])
        

        measureIntervalLabel = NSTextField(labelWithString: "0")
        measureIntervalLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        measureIntervalLabel.textColor = NSColor.systemGreen
        measureIntervalLabel.alignment = .center
        intervalStack.addArrangedSubview(measureIntervalLabel)
        
        let msLabel = NSTextField(labelWithString: "milliseconds")
        msLabel.font = NSFont.systemFont(ofSize: 12)
        msLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        intervalStack.addArrangedSubview(msLabel)
        
        mainStack.addArrangedSubview(intervalCard)
        
        // History Section
        let historyLabel = NSTextField(labelWithString: "Recent Intervals")
        historyLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        historyLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        mainStack.addArrangedSubview(historyLabel)
        
        // Empty State Hint
        emptyStateLabel = NSTextField(labelWithString: "Click your mouse wheel\nto measure interval")
        emptyStateLabel.font = NSFont.systemFont(ofSize: 13)
        emptyStateLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        emptyStateLabel.alignment = .center
        emptyStateLabel.cell?.wraps = true
        mainStack.addArrangedSubview(emptyStateLabel)
        
        measureHistoryView = NSStackView()
        measureHistoryView.orientation = .vertical
        measureHistoryView.spacing = 4
        measureHistoryView.alignment = .leading
        mainStack.addArrangedSubview(measureHistoryView)
        
        // Initial state
        measureHistoryView.isHidden = true
        emptyStateLabel.isHidden = false
        
        // Spacer
        

        mainStack.addArrangedSubview(NSView())
        
        // Recommendation
        let recommendLabel = NSTextField(wrappingLabelWithString: "💡 Set debounce time slightly higher than your typical interval to filter bounces.")
        recommendLabel.font = NSFont.systemFont(ofSize: 11)
        recommendLabel.textColor = NSColor.white.withAlphaComponent(0.5)
        mainStack.addArrangedSubview(recommendLabel)
        
        return container
    }
    
    private func createHistoryRow(interval: Double?, index: Int) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        
        
        let numLabel = NSTextField(labelWithString: interval != nil ? "\(index)." : "")
        numLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        numLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        numLabel.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        let valueLabel = NSTextField(labelWithString: interval != nil ? String(format: "%.0f ms", interval!) : "")
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        valueLabel.textColor = interval != nil ? .white : NSColor.white.withAlphaComponent(0.3)
        
        row.addArrangedSubview(numLabel)
        row.addArrangedSubview(valueLabel)
        row.addArrangedSubview(NSView())
        
        return row
    }
    
    // MARK: - Animation
    
    @objc private func showMeasure(_ sender: Any) {
        guard !isShowingMeasure else { return }
        isShowingMeasure = true
        
        // Start measurement mode
        appDelegate?.mouseHook.measurementMode = true
        clickIntervals = []
        updateMeasureHistory()
        measureIntervalLabel.stringValue = "0"
        
        measureView.frame = containerView.bounds
        measureView.frame.origin.x = containerView.bounds.width
        containerView.addSubview(measureView)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            mainView.animator().frame.origin.x = -containerView.bounds.width
            measureView.animator().frame.origin.x = 0
        }, completionHandler: {
            self.mainView.removeFromSuperview()
        })
    }
    
    @objc private func backToMain(_ sender: Any) {
        guard isShowingMeasure || isShowingAbout else { return }
        
        // Stop measurement mode if coming from measure
        if isShowingMeasure {
            appDelegate?.mouseHook.measurementMode = false
        }
        
        isShowingMeasure = false
        isShowingAbout = false
        
        mainView.frame = containerView.bounds
        mainView.frame.origin.x = -containerView.bounds.width
        containerView.addSubview(mainView)
        
        // Find which view to animate out
        let currentView = isShowingMeasure ? measureView : (isShowingAbout ? aboutView : (containerView.subviews.first { $0 != mainView }))
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            currentView?.animator().frame.origin.x = containerView.bounds.width
            mainView.animator().frame.origin.x = 0
        }, completionHandler: {
            currentView?.removeFromSuperview()
        })
    }
    
    // MARK: - About View
    
    private func createAboutView() -> NSView {
        let container = NSView(frame: view.bounds)
        container.wantsLayer = true
        
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 12
        mainStack.edgeInsets = NSEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Header with back button
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        
        let backBtn = NSButton(title: "← Back", target: self, action: #selector(backToMain(_:)))
        backBtn.bezelStyle = .inline
        backBtn.isBordered = false
        backBtn.contentTintColor = .white
        
        let titleLabel = NSTextField(labelWithString: "About")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        
        headerStack.addArrangedSubview(backBtn)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(NSView())
        mainStack.addArrangedSubview(headerStack)
        
        // App info card
        let infoCard = createCard()
        let infoStack = NSStackView()
        infoStack.orientation = .horizontal
        infoStack.spacing = 12
        infoStack.alignment = .centerY
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)
        
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12)
        ])
        
        // App icon
        let iconView = NSImageView()
        if let iconPath = Bundle.main.path(forResource: "mouse_icon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            iconView.image = icon
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        
        let appNameLabel = NSTextField(labelWithString: "MouseWheelRepairix")
        appNameLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        appNameLabel.textColor = .white
        
        let versionLabel = NSTextField(labelWithString: "Version \(AppVersion.version) (Build \(AppVersion.buildNumber))")
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        
        let copyrightLabel = NSTextField(labelWithString: "© 2026 Venice Wave Records")
        copyrightLabel.font = NSFont.systemFont(ofSize: 10)
        copyrightLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        
        textStack.addArrangedSubview(appNameLabel)
        textStack.addArrangedSubview(versionLabel)
        textStack.addArrangedSubview(copyrightLabel)
        
        infoStack.addArrangedSubview(iconView)
        infoStack.addArrangedSubview(textStack)
        infoStack.addArrangedSubview(NSView())
        
        mainStack.addArrangedSubview(infoCard)
        
        // Changelog header
        let changelogHeader = NSTextField(labelWithString: "What's New")
        changelogHeader.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        changelogHeader.textColor = .white
        mainStack.addArrangedSubview(changelogHeader)
        
        // Changelog scroll view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let changelogStack = NSStackView()
        changelogStack.orientation = .vertical
        changelogStack.alignment = .leading
        changelogStack.spacing = 12
        
        // Version 1.1.0
        addChangelogEntry(to: changelogStack, version: "1.1.0", items: [
            "🎯 Click interval measurement tool",
            "📊 Real-time timing display",
            "🔧 Modern popover UI with animations",
            "💜 Beautiful gradient design"
        ])
        
        // Version 1.0.0
        addChangelogEntry(to: changelogStack, version: "1.0.0", items: [
            "🖱️ Mouse wheel debouncing",
            "⚙️ Configurable debounce time",
            "🚀 Start at login support",
            "🎨 Menu bar integration"
        ])
        
        scrollView.documentView = changelogStack
        changelogStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalToConstant: 180),
            changelogStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -20)
        ])
        
        mainStack.addArrangedSubview(scrollView)
        
        // GitHub link
        let githubBtn = NSButton(title: "⭐ Star on GitHub", target: self, action: #selector(openGitHub(_:)))
        githubBtn.bezelStyle = .rounded
        mainStack.addArrangedSubview(githubBtn)
        
        return container
    }
    
    private func addChangelogEntry(to stack: NSStackView, version: String, items: [String]) {
        let entryStack = NSStackView()
        entryStack.orientation = .vertical
        entryStack.alignment = .leading
        entryStack.spacing = 4
        
        let versionLabel = NSTextField(labelWithString: "v\(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        versionLabel.textColor = NSColor.systemYellow
        entryStack.addArrangedSubview(versionLabel)
        
        for item in items {
            let itemLabel = NSTextField(labelWithString: item)
            itemLabel.font = NSFont.systemFont(ofSize: 10)
            itemLabel.textColor = NSColor.white.withAlphaComponent(0.7)
            entryStack.addArrangedSubview(itemLabel)
        }
        
        stack.addArrangedSubview(entryStack)
    }
    
    @objc private func showAboutView(_ sender: Any) {
        guard !isShowingAbout && !isShowingMeasure else { return }
        isShowingAbout = true
        
        aboutView.frame = containerView.bounds
        aboutView.frame.origin.x = containerView.bounds.width
        containerView.addSubview(aboutView)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            mainView.animator().frame.origin.x = -containerView.bounds.width
            aboutView.animator().frame.origin.x = 0
        }, completionHandler: {
            self.mainView.removeFromSuperview()
        })
    }
    
    @objc private func openGitHub(_ sender: Any) {
        if let url = URL(string: "https://github.com/ermuraten/MouseWheelRepairix") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Header
    
    private func createHeader() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = NSImageView()
        if let iconPath = Bundle.main.path(forResource: "mouse_icon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            iconView.image = icon
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        let titleLabel = NSTextField(labelWithString: "MouseWheelRepairix")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let versionLabel = NSTextField(labelWithString: "v\(AppVersion.version)")
        versionLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        versionLabel.textColor = NSColor.white.withAlphaComponent(0.5)
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            versionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            versionLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Cards Grid
    
    private func createCardsGrid() -> NSView {
        let grid = NSStackView()
        grid.orientation = .vertical
        grid.spacing = 10
        grid.distribution = .fillEqually
        
        let row1 = NSStackView()
        row1.orientation = .horizontal
        row1.spacing = 10
        row1.distribution = .fillEqually
        
        let statusCard = createStatusCard()
        let blockedCard = createBlockedCard()
        row1.addArrangedSubview(statusCard)
        row1.addArrangedSubview(blockedCard)
        
        let row2 = NSStackView()
        row2.orientation = .horizontal
        row2.spacing = 10
        row2.distribution = .fillEqually
        
        let intervalCard = createIntervalCard()
        let loginCard = createLoginCard()
        row2.addArrangedSubview(intervalCard)
        row2.addArrangedSubview(loginCard)
        
        grid.addArrangedSubview(row1)
        grid.addArrangedSubview(row2)
        
        // Ensure rows have equal widths
        row2.widthAnchor.constraint(equalTo: row1.widthAnchor).isActive = true
        
        return grid
    }
    
    private func createStatusCard() -> NSView {
        let card = createCard()
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        let titleLabel = NSTextField(labelWithString: "Status")
        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(titleLabel)
        
        let statusStack = NSStackView()
        statusStack.orientation = .horizontal
        statusStack.spacing = 6
        
        statusDot = NSView()
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = NSColor.systemGreen.cgColor
        statusDot.layer?.cornerRadius = 4
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        statusTextLabel = NSTextField(labelWithString: "Active")
        statusTextLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        statusTextLabel.textColor = .white
        // Set minimum width to fit "Inactive" so layout doesn't jump
        statusTextLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTextLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        
        statusStack.addArrangedSubview(statusDot)
        statusStack.addArrangedSubview(statusTextLabel)
        stack.addArrangedSubview(statusStack)
        
        statusToggle = NSSwitch()
        statusToggle.state = .on
        statusToggle.target = self
        statusToggle.action = #selector(toggleStatus(_:))
        stack.addArrangedSubview(statusToggle)
        
        return card
    }
    
    private func createBlockedCard() -> NSView {
        let card = createCard()
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        let titleLabel = NSTextField(labelWithString: "Blocked")
        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(titleLabel)
        
        blockedCountLabel = NSTextField(labelWithString: "0")
        blockedCountLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        blockedCountLabel.textColor = NSColor.systemOrange
        stack.addArrangedSubview(blockedCountLabel)
        
        let subtitleLabel = NSTextField(labelWithString: "this session")
        subtitleLabel.font = NSFont.systemFont(ofSize: 9, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        stack.addArrangedSubview(subtitleLabel)
        
        return card
    }
    
    private func createIntervalCard() -> NSView {
        let card = createCard()
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        let titleLabel = NSTextField(labelWithString: "Interval")
        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(titleLabel)
        
        lastIntervalLabel = NSTextField(labelWithString: "—")
        lastIntervalLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .bold)
        lastIntervalLabel.textColor = NSColor.systemTeal
        stack.addArrangedSubview(lastIntervalLabel)
        
        let subtitleLabel = NSTextField(labelWithString: "milliseconds")
        subtitleLabel.font = NSFont.systemFont(ofSize: 9, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        stack.addArrangedSubview(subtitleLabel)
        
        return card
    }
    
    private func createLoginCard() -> NSView {
        let card = createCard()
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        let titleLabel = NSTextField(labelWithString: "Auto-Start")
        titleLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.6)
        stack.addArrangedSubview(titleLabel)
        
        let loginSwitch = NSSwitch()
        loginSwitch.state = appDelegate?.launchAtLogin == true ? .on : .off
        loginSwitch.target = self
        loginSwitch.action = #selector(toggleLaunchAtLogin(_:))
        stack.addArrangedSubview(loginSwitch)
        
        let statusLabel = NSTextField(labelWithString: "at login")
        statusLabel.font = NSFont.systemFont(ofSize: 9, weight: .regular)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        stack.addArrangedSubview(statusLabel)
        
        return card
    }
    
    // MARK: - Slider Card
    
    private func createSliderCard() -> NSView {
        let card = createCard()
        
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        
        let titleLabel = NSTextField(labelWithString: "Debounce Time")
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        
        let currentMs = Int((appDelegate?.mouseHook.debounceInterval ?? 0.1) * 1000)
        
        debounceLabel = NSTextField(labelWithString: "\(currentMs)ms")
        debounceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        debounceLabel.textColor = NSColor.systemYellow
        debounceLabel.alignment = .right
        
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(NSView())
        headerStack.addArrangedSubview(debounceLabel)
        stack.addArrangedSubview(headerStack)
        
        debounceSlider = NSSlider(value: Double(currentMs), minValue: 10, maxValue: 500, target: self, action: #selector(debounceChanged(_:)))
        debounceSlider.isContinuous = true
        stack.addArrangedSubview(debounceSlider)
        
        let labelsStack = NSStackView()
        labelsStack.orientation = .horizontal
        
        let minLabel = NSTextField(labelWithString: "10ms")
        minLabel.font = NSFont.systemFont(ofSize: 9)
        minLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        
        let maxLabel = NSTextField(labelWithString: "500ms")
        maxLabel.font = NSFont.systemFont(ofSize: 9)
        maxLabel.textColor = NSColor.white.withAlphaComponent(0.4)
        maxLabel.alignment = .right
        
        labelsStack.addArrangedSubview(minLabel)
        labelsStack.addArrangedSubview(NSView())
        labelsStack.addArrangedSubview(maxLabel)
        stack.addArrangedSubview(labelsStack)
        
        return card
    }
    
    // MARK: - Action Buttons
    
    private func createActionButtons() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        
        let measureBtn = NSButton(title: "📊 Measure", target: self, action: #selector(showMeasure(_:)))
        measureBtn.bezelStyle = .rounded
        
        let donateBtn = NSButton(title: "☕ Donate", target: self, action: #selector(openDonation(_:)))
        donateBtn.bezelStyle = .rounded
        
        stack.addArrangedSubview(measureBtn)
        stack.addArrangedSubview(donateBtn)
        
        return stack
    }
    
    // MARK: - Footer
    
    private func createFooter() -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        
        let aboutBtn = NSButton(title: "About", target: self, action: #selector(showAboutView(_:)))
        aboutBtn.bezelStyle = .inline
        aboutBtn.isBordered = false
        
        let quitBtn = NSButton(title: "Quit", target: self, action: #selector(quitApp(_:)))
        quitBtn.bezelStyle = .inline
        quitBtn.isBordered = false
        quitBtn.contentTintColor = .systemRed
        
        stack.addArrangedSubview(aboutBtn)
        stack.addArrangedSubview(NSView())
        stack.addArrangedSubview(quitBtn)
        
        return stack
    }
    
    // MARK: - Helper
    
    private func createCard() -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        card.layer?.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 85)
        ])
        
        return card
    }
    
    // MARK: - Actions
    
    @objc private func toggleStatus(_ sender: NSSwitch) {
        let isActive = sender.state == .on
        appDelegate?.toggleRepair(sender)
        // Update UI immediately
        statusDot?.layer?.backgroundColor = isActive ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
        statusTextLabel?.stringValue = isActive ? "Active" : "Inactive"
    }
    
    @objc private func debounceChanged(_ sender: NSSlider) {
        let value = Int(sender.doubleValue)
        debounceLabel?.stringValue = "\(value)ms"
        appDelegate?.updateDebounceTime(value)
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSSwitch) {
        appDelegate?.toggleLaunchAtLogin(sender)
    }
    
    @objc private func openDonation(_ sender: Any) {
        if let url = URL(string: "https://paypal.me/VeniceWaveRecords") {
            NSWorkspace.shared.open(url)
        }
        appDelegate?.closePopover()
    }
    
    @objc private func quitApp(_ sender: Any) {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Public Methods
    
    func updateStats(blockedCount: Int, lastInterval: Int?) {
        guard isViewLoaded else { return }
        blockedCountLabel?.stringValue = "\(blockedCount)"
        if let interval = lastInterval {
            lastIntervalLabel?.stringValue = "\(interval)"
        } else {
            lastIntervalLabel?.stringValue = "—"
        }
    }
    
    func updateDebounceValue(_ value: Int) {
        guard isViewLoaded else { return }
        debounceSlider?.doubleValue = Double(value)
        debounceLabel?.stringValue = "\(value)ms"
    }
    
    func updateStatus(isActive: Bool) {
        guard isViewLoaded else { return }
        statusToggle?.state = isActive ? .on : .off
        statusDot?.layer?.backgroundColor = isActive ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
        statusTextLabel?.stringValue = isActive ? "Active" : "Inactive"
    }
    
    func addMeasurementInterval(_ intervalMs: Double) {
        clickIntervals.insert(intervalMs, at: 0)
        if clickIntervals.count > maxIntervals {
            clickIntervals.removeLast()
        }
        
        // Update main view's interval display
        lastIntervalLabel?.stringValue = String(format: "%.0f", intervalMs)
        
        // Update measure view display if showing
        if isShowingMeasure {
            measureIntervalLabel?.stringValue = String(format: "%.0f", intervalMs)
            measureIntervalLabel?.textColor = intervalMs < 100 ? NSColor.systemRed : NSColor.systemGreen
            updateMeasureHistory()
        }
    }
    
    private func updateMeasureHistory() {
        guard let historyView = measureHistoryView else { return }
        
        let hasData = !clickIntervals.isEmpty
        emptyStateLabel?.isHidden = hasData
        historyView.isHidden = !hasData
        
        // Remove old rows
        for view in historyView.arrangedSubviews {
            historyView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        if hasData {
            // Add rows (always 4)
            for i in 0..<4 {
                let interval = i < clickIntervals.count ? clickIntervals[i] : nil
                let row = createHistoryRow(interval: interval, index: i + 1)
                historyView.addArrangedSubview(row)
            }
        }
    }
}
