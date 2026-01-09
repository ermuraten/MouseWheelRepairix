import Cocoa
import CoreGraphics

class MouseHook {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastClickTime: TimeInterval = 0
    
    // Separate timing for measurement (tracks ALL clicks including debounced ones)
    private var lastMeasurementTime: TimeInterval = 0
    
    // Default debounce interval in seconds (100ms)
    var debounceInterval: TimeInterval = 0.1
    
    // Measurement mode
    var measurementMode: Bool = false {
        didSet {
            if measurementMode {
                // Reset measurement time when entering measurement mode
                lastMeasurementTime = 0
                print("[DEBUG] Measurement mode ENABLED")
            } else {
                print("[DEBUG] Measurement mode DISABLED")
            }
        }
    }
    var clickIntervalCallback: ((Double) -> Void)?
    
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
                
                // MEASUREMENT MODE: Track ALL clicks with separate timer
                if measurementMode {
                    print("[MEASUREMENT] Mode is ON, lastTime: \(lastMeasurementTime)")
                    if lastMeasurementTime > 0 {
                        let intervalMs = (now - lastMeasurementTime) * 1000.0
                        print("[MEASUREMENT] Interval: \(String(format: "%.1f", intervalMs))ms")
                        DispatchQueue.main.async { [weak self] in
                            self?.clickIntervalCallback?(intervalMs)
                        }
                    } else {
                        print("[MEASUREMENT] First click registered!")
                    }
                    // ALWAYS update measurement time for EVERY click
                    lastMeasurementTime = now
                }
                
                // DEBOUNCE LOGIC: Uses separate timer
                let timeSinceLastClick = now - lastClickTime
                
                if timeSinceLastClick < debounceInterval {
                    print("Debounced! (Delta: \(String(format: "%.3f", timeSinceLastClick))s < \(debounceInterval)s)")
                    // Block the event
                    return nil
                }
                
                lastClickTime = now
            }
        }
        
        // Pass the event through
        return Unmanaged.passUnretained(event)
    }
}

