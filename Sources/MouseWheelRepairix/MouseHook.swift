import Cocoa
import CoreGraphics

class MouseHook {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var virtuallyDown: Bool = false
    private var lastPassedDownTime: TimeInterval = 0
    private var lastPassedUpTime: TimeInterval = 0
    private var lastPhysicalDownTime: TimeInterval = 0
    private var lastPhysicalUpTime: TimeInterval = 0
    
    // Default debounce interval in seconds (100ms)
    var debounceInterval: TimeInterval = 0.1
    
    // Whether debouncing is active
    var isActive: Bool = true
    
    // Measurement mode
    var measurementMode: Bool = false {
        didSet {
            if measurementMode {
                print("[DEBUG] Measurement mode ENABLED")
            } else {
                print("[DEBUG] Measurement mode DISABLED")
            }
        }
    }
    var rawEventCallback: ((_ isDown: Bool, _ timestamp: TimeInterval) -> Void)?
    var blockedClickCallback: (() -> Void)?
    
    // Middle mouse button number (usually 2)
    private let middleButtonNumber: Int64 = 2

    init() {}

    func start() {
        print("Starting MouseHook...")
        
        // Create an event tap to intercept mouse down events globally
        let eventMask = (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.otherMouseUp.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Unsafe pointer bridge to get the instance
                let hook = Unmanaged<MouseHook>.fromOpaque(refcon!).takeUnretainedValue()
                return hook.handle(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap. Check Accessibility permissions.")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("MouseHook started successfully.")
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // DEBUG: Log ALL events to see what's coming in
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        print("[EVENT] Type: \(type.rawValue), Button: \(buttonNumber), measurementMode: \(measurementMode)")
        
        // Only interested in middle mouse button (button number 2)
        if buttonNumber == middleButtonNumber {
            
            if type == .otherMouseDown {
                print("[MIDDLE CLICK] Detected at \(Date())")
                let now = Date().timeIntervalSince1970
                
                if measurementMode {
                    DispatchQueue.main.async { [weak self] in
                        self?.rawEventCallback?(true, now)
                    }
                }
                lastPhysicalDownTime = now
                
                if isActive {
                    let downToDown = now - lastPassedDownTime
                    let upToDown = now - lastPassedUpTime
                    
                    if virtuallyDown {
                        // Make-bounce physically Down while already OS virtual Down
                        DispatchQueue.main.async { [weak self] in self?.blockedClickCallback?() }
                        return nil
                    }
                    
                    if downToDown < debounceInterval {
                        // Too fast make-bounce or multi-click
                        DispatchQueue.main.async { [weak self] in self?.blockedClickCallback?() }
                        return nil
                    }
                    
                    if upToDown < 0.05 {
                        // Break-bounce (shortly after physical/virtual release)
                        DispatchQueue.main.async { [weak self] in self?.blockedClickCallback?() }
                        return nil
                    }
                    
                    virtuallyDown = true
                    lastPassedDownTime = now
                } else {
                    virtuallyDown = true
                    lastPassedDownTime = now
                }
                
            } else if type == .otherMouseUp {
                let now = Date().timeIntervalSince1970
                
                if measurementMode {
                    DispatchQueue.main.async { [weak self] in
                        self?.rawEventCallback?(false, now)
                    }
                }
                lastPhysicalUpTime = now
                
                if isActive {
                    if !virtuallyDown {
                        // OS thinks it's already Up. Block extra physical UPs.
                        return nil
                    }
                    
                    virtuallyDown = false
                    lastPassedUpTime = now
                } else {
                    virtuallyDown = false
                    lastPassedUpTime = now
                }
            }
        }
        
        // Pass the event through
        return Unmanaged.passUnretained(event)
    }
}

