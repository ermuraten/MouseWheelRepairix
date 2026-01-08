import Cocoa

let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
// .accessory makes it not show in the Dock, only menu bar
app.setActivationPolicy(.accessory)
app.run()
