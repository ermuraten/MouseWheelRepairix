import Cocoa
import CoreGraphics

class MouseHook {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastClickTime: TimeInterval = 0
    
    // Default debounce interval in seconds (100ms)
    var debounceInterval: TimeInterval = 0.1
    
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
        // Only interested in middle mouse button (button number 2)
        if event.getIntegerValueField(.mouseEventButtonNumber) == middleButtonNumber {
            
            if type == .otherMouseDown {
                let now = Date().timeIntervalSince1970
                let timeSinceLastClick = now - lastClickTime
                
                // Debug print
                // print("Middle Click detected. Delta: \(timeSinceLastClick)")

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
