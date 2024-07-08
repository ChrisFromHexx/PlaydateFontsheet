//
//  Filters.swift
//
//
//  Created by Chris Samuels (Hexagonal Studios Limited) on 06/07/2024.
//

import Cocoa

extension Process {
    func pixelate(image: NSImage, threshold: CGFloat) -> NSImage {
        let width = Int(image.size.width)
        let height = Int(image.size.height)

        guard let representation = NSBitmapImageRep(bitmapDataPlanes: nil,
                                                    pixelsWide: width,
                                                    pixelsHigh: height,
                                                    bitsPerSample: 8,
                                                    samplesPerPixel: 4,
                                                    hasAlpha: true,
                                                    isPlanar: false,
                                                    colorSpaceName: .deviceRGB,
                                                    bytesPerRow: width * 4,
                                                    bitsPerPixel: 32),
            let context = NSGraphicsContext(bitmapImageRep: representation)
        else {
            return image
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        image.draw(at: NSZeroPoint, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        var blackPixel: [Int] = [0, 0, 0, 255]
        var clearPixel: [Int] = [255, 255, 255, 0]

        for y in 0 ..< height {
            for x in 0 ..< width {
                if let color = representation.colorAt(x: x, y: y) {
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var brightness: CGFloat = 0
                    var alpha: CGFloat = 0
                    color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                    if alpha < threshold {
                        representation.setPixel(&clearPixel, atX: x, y: y)
                    } else {
                        representation.setPixel(&blackPixel, atX: x, y: y)
                    }
                }
            }
        }

        guard let cgImage = representation.cgImage
        else {
            return image
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}
