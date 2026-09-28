#!/usr/bin/env swift

import AppKit
import ImageIO
import UniformTypeIdentifiers

let canvasWidth = 720
let canvasHeight = 920
let outputPath = CommandLine.arguments.dropFirst().first
    ?? "Documentation/Media/hijri-calendar-demo.gif"

struct Palette {
    static let backdrop = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.95, alpha: 1)
    static let surface = NSColor.white
    static let ink = NSColor(calibratedWhite: 0.10, alpha: 1)
    static let secondary = NSColor(calibratedWhite: 0.43, alpha: 1)
    static let muted = NSColor(calibratedWhite: 0.74, alpha: 1)
    static let teal = NSColor(calibratedRed: 0.02, green: 0.52, blue: 0.47, alpha: 1)
    static let tealSoft = NSColor(calibratedRed: 0.80, green: 0.93, blue: 0.90, alpha: 1)
    static let orange = NSColor(calibratedRed: 0.96, green: 0.51, blue: 0.16, alpha: 1)
    static let line = NSColor(calibratedWhite: 0.90, alpha: 1)
}

func rectFromTop(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: CGFloat(canvasHeight) - y - height, width: width, height: height)
}

func fill(_ color: NSColor, rect: NSRect, radius: CGFloat = 0) {
    color.setFill()
    if radius > 0 {
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    } else {
        rect.fill()
    }
}

func drawText(
    _ text: String,
    rect: NSRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    (text as NSString).draw(
        in: rect,
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    )
}

func makeFrame(step: Int) -> CGImage {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: canvasWidth,
        pixelsHigh: canvasHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: canvasWidth, height: canvasHeight)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    fill(Palette.backdrop, rect: rectFromTop(0, 0, 720, 920))

    drawText(
        "HijriCalendar",
        rect: rectFromTop(58, 34, 420, 44),
        font: .systemFont(ofSize: 32, weight: .bold),
        color: Palette.ink
    )
    drawText(
        "SWIFTUI  +  UIKIT",
        rect: rectFromTop(58, 82, 360, 24),
        font: .monospacedSystemFont(ofSize: 14, weight: .semibold),
        color: Palette.teal
    )

    let phone = rectFromTop(44, 126, 632, 724)
    fill(NSColor(calibratedWhite: 0, alpha: 0.07), rect: phone.offsetBy(dx: 0, dy: -9), radius: 34)
    fill(Palette.surface, rect: phone, radius: 34)

    drawText(
        "‹",
        rect: rectFromTop(82, 172, 52, 50),
        font: .systemFont(ofSize: 36, weight: .regular),
        color: Palette.teal,
        alignment: .center
    )
    drawText(
        "Ramadan 1447 AH",
        rect: rectFromTop(170, 178, 380, 36),
        font: .systemFont(ofSize: 24, weight: .semibold),
        color: Palette.ink,
        alignment: .center
    )
    drawText(
        "›",
        rect: rectFromTop(586, 172, 52, 50),
        font: .systemFont(ofSize: 36, weight: .regular),
        color: Palette.teal,
        alignment: .center
    )

    let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    let gridX: CGFloat = 76
    let gridWidth: CGFloat = 568
    let columnWidth = gridWidth / 7
    for (column, symbol) in weekdaySymbols.enumerated() {
        drawText(
            symbol,
            rect: rectFromTop(gridX + CGFloat(column) * columnWidth, 242, columnWidth, 28),
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: Palette.secondary,
            alignment: .center
        )
    }

    let leadingDays = [27, 28, 29]
    let calendarValues = leadingDays + Array(1...30) + Array(1...9)
    let selectedStart = 7
    let selectedEnd = min(16, 7 + step)
    let events: Set<Int> = [1, 10, 18, 27]
    let gridTop: CGFloat = 286
    let rowHeight: CGFloat = 76

    for index in 0..<42 {
        let row = index / 7
        let column = index % 7
        let day = calendarValues[index]
        let isCurrentMonth = index >= leadingDays.count && index < leadingDays.count + 30
        let isSelected = isCurrentMonth && day >= selectedStart && day <= selectedEnd
        let isEndpoint = isCurrentMonth && (day == selectedStart || day == selectedEnd)
        let centerX = gridX + CGFloat(column) * columnWidth + columnWidth / 2
        let centerY = gridTop + CGFloat(row) * rowHeight + 27

        if isSelected {
            fill(
                isEndpoint ? Palette.teal : Palette.tealSoft,
                rect: rectFromTop(centerX - 25, centerY - 25, 50, 50),
                radius: 16
            )
        }

        drawText(
            String(day),
            rect: rectFromTop(centerX - columnWidth / 2, centerY - 12, columnWidth, 28),
            font: .systemFont(ofSize: 18, weight: isEndpoint ? .semibold : .regular),
            color: isEndpoint ? .white : (isCurrentMonth ? Palette.ink : Palette.muted),
            alignment: .center
        )

        if isCurrentMonth && events.contains(day) {
            fill(
                Palette.orange,
                rect: rectFromTop(centerX - 3, centerY + 19, 6, 6),
                radius: 3
            )
        }
    }

    fill(Palette.line, rect: rectFromTop(76, 752, 568, 1))
    fill(Palette.teal, rect: rectFromTop(78, 778, 16, 16), radius: 5)
    drawText(
        "Range: 7–\(selectedEnd) Ramadan",
        rect: rectFromTop(108, 774, 270, 28),
        font: .systemFont(ofSize: 16, weight: .medium),
        color: Palette.ink
    )
    fill(Palette.orange, rect: rectFromTop(430, 783, 7, 7), radius: 4)
    drawText(
        "Events",
        rect: rectFromTop(450, 774, 120, 28),
        font: .systemFont(ofSize: 16, weight: .medium),
        color: Palette.secondary
    )

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.cgImage!
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.gif.identifier as CFString,
    12,
    nil
) else {
    fatalError("Could not create GIF destination")
}

let gifProperties: [CFString: Any] = [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFLoopCount: 0
    ]
]
CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

for step in 0..<12 {
    let frameProperties: [CFString: Any] = [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFDelayTime: step == 11 ? 1.2 : 0.16
        ]
    ]
    CGImageDestinationAddImage(destination, makeFrame(step: step), frameProperties as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not finalize GIF")
}

print("Wrote \(outputURL.path)")
