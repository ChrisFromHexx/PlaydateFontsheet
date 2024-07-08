//
//  Extensions.swift
//
//
//  Created by Chris Samuels (Hexagonal Studios Limited) on 06/07/2024.
//
import Cocoa

extension NSImage {
    var ciImage: CIImage {
        let data = tiffRepresentation!
        let bitmap = NSBitmapImageRep(data: data)!
        let ci = CIImage(bitmapImageRep: bitmap)!
        return ci
    }

    static func fromCIImage(_ ciImage: CIImage) -> NSImage {
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}

extension Foundation.URL {
    init(fileURLWithPath: String, isDirectory: Bool, expand: Bool) {
        if !expand {
            self = Foundation.URL(fileURLWithPath: fileURLWithPath, isDirectory: isDirectory)
        }
        let expandedPath = (fileURLWithPath as NSString).expandingTildeInPath
        self = Foundation.URL(fileURLWithPath: expandedPath, isDirectory: isDirectory)
    }
}
