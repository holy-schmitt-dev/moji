#!/usr/bin/env swift

import Cocoa

// DMG background dimensions (2x for retina)
let width: CGFloat = 1200
let height: CGFloat = 800

// Create the image
let image = NSImage(size: NSSize(width: width, height: height))

image.lockFocus()

// Draw gradient background
let gradient = NSGradient(colors: [
    NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0),
    NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
])!
gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 270)

// Draw subtle purple glow in center
let glowGradient = NSGradient(colors: [
    NSColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.15),
    NSColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.0)
])!
let glowRect = NSRect(x: width/4, y: height/4, width: width/2, height: height/2)
glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: NSPoint.zero)

// Draw arrow
let arrowPath = NSBezierPath()
let arrowY: CGFloat = height / 2 - 20
let arrowStartX: CGFloat = 480  // Between the two icon positions
let arrowEndX: CGFloat = 720
let arrowHeadSize: CGFloat = 30

// Arrow line
arrowPath.move(to: NSPoint(x: arrowEndX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowStartX, y: arrowY))

// Arrow head
arrowPath.move(to: NSPoint(x: arrowStartX + arrowHeadSize, y: arrowY + arrowHeadSize))
arrowPath.line(to: NSPoint(x: arrowStartX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowStartX + arrowHeadSize, y: arrowY - arrowHeadSize))

arrowPath.lineWidth = 8
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round

NSColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.8).setStroke()
arrowPath.stroke()

// Draw "Drag to Install" text
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 28, weight: .medium),
    .foregroundColor: NSColor(white: 1.0, alpha: 0.6),
    .paragraphStyle: paragraphStyle
]

let text = "Drag to Install"
let textRect = NSRect(x: 0, y: height - 120, width: width, height: 50)
text.draw(in: textRect, withAttributes: attributes)

image.unlockFocus()

// Save as PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    let outputPath = CommandLine.arguments.count > 1
        ? CommandLine.arguments[1]
        : "dmg-background.png"
    try! pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Created: \(outputPath)")
}
