import Cocoa

guard CommandLine.arguments.count == 3 else {
    print("Usage: IconProcessor <input> <output>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let image = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load image")
    exit(1)
}

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData) else {
    print("Failed to get bitmap representation")
    exit(1)
}

// Create new bitmap with per-pixel iteration
let width = bitmap.pixelsWide
let height = bitmap.pixelsHigh
let newBitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width,
    pixelsHigh: height,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

for y in 0..<height {
    for x in 0..<width {
        if let color = bitmap.colorAt(x: x, y: y) {
            // Check brightness. If bright white, make transparent.
            // If dark, keep as black (or opaque).
            // We want the shape (black) to be the visible part (black or template).
            
            // Brightness 0..1
            var brightness = color.brightnessComponent
            
            // In the generated image:
            // Black Shape (Background in previous context? No, user wanted Black Mouse on White BG)
            // So Black pixels are the MOUSE. White pixels are BG.
            
            // If pixel is White (Brightness > 0.8), set Alpha 0.
            // If pixel is Black (Brightness < 0.8), keep it.
            
            if brightness > 0.9 {
                // Transparent
                newBitmap.setColor(NSColor.clear, atX: x, y: y)
            } else {
                // Black (Template color)
                newBitmap.setColor(NSColor.black, atX: x, y: y)
            }
        }
    }
}

guard let pngData = newBitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Created \(outputPath)")
