//
//  Process.swift
//
//
//  Created by Chris Samuels (Hexagonal Studios Limited) on 06/07/2024.
//

import Cocoa
import Foundation

final class Process {
    let margin: CGFloat = 1.0
    let descenderComp: CGFloat = 2.0
    let columnCount: Double = 16
    let debug = false

    let fontSheetFileName: String
    let fontName: String
    let glyphURL: URL
    let outputFolderURL: URL
    let size: CGFloat
    let weight: String?
    let threshold: CGFloat
    let embedded: Bool

    var metaList: [FontMeta] = []

    struct FontMeta {
        let glyph: String
        let width: Int
    }

    var seen: Set<String> = .init()

    // MARK: - Setup

    init?(fontSheetFileName: String,
          fontName: String,
          glyphFile: String,
          outputFolder: String,
          size: Float,
          weight: String?,
          threshold: Float?,
          embedded: Bool)
    {
        let glyphURL = URL(fileURLWithPath: glyphFile, isDirectory: false, expand: true)
        let outputFolderURL = URL(fileURLWithPath: outputFolder, isDirectory: true, expand: true)

        self.outputFolderURL = outputFolderURL
        self.glyphURL = glyphURL
        self.size = CGFloat(size)
        self.threshold = CGFloat(threshold ?? 0.5)
        self.fontName = fontName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.fontSheetFileName = fontSheetFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.embedded = embedded
        self.weight = weight?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Execution

    func run() {
        print("Loading glyph file \(glyphURL.path) for \(fontSheetFileName)")

        do {
            guard let font = NSFont(name: fontName, size: size)
            else {
                print("A font by the name '\(fontName)' can not be found installed on this computer. Find the 'PostScript Name' of your font in the app 'Font Book'")
                return
            }

            let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            let textFontAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: font as Any,
                NSAttributedString.Key.foregroundColor: NSColor.black,
                NSAttributedString.Key.backgroundColor: NSColor.clear,
                NSAttributedString.Key.paragraphStyle: textStyle,
            ]

            let content = try String(contentsOf: glyphURL, encoding: .utf8)
            let glyphList = content.components(separatedBy: .whitespacesAndNewlines)

            print("\(glyphList.count) glyphs to build for \(fontSheetFileName)")

            let (width, height) = cellSize(glyphs: glyphList, textFontAttributes: textFontAttributes)

            if let fontSheetImage = build(from: glyphList,
                                          textFontAttributes: textFontAttributes,
                                          width: width,
                                          height: height)
            {
                save(image: fontSheetImage,
                     width: width,
                     height: height)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension Process {
    // MARK: - Assemble

    func build(from glyphs: [String],
               textFontAttributes: [NSAttributedString.Key: Any],
               width: Int,
               height: Int) -> NSImage?
    {
        let rowCount = ceil(Double(glyphs.count) / columnCount)
        let dimensions = CGSize(width: CGFloat(width) * columnCount, height: CGFloat(height) * rowCount)

        print("Setting cell size to \(width)x\(height)px for sheet size of \(Int(dimensions.width))x\(Int(dimensions.height))px ")

        let fontSheetImage: NSImage = render(glyphs: glyphs,
                                             textFontAttributes: textFontAttributes,
                                             dimensions: dimensions,
                                             width: width,
                                             height: height)

        return pixelate(image: fontSheetImage, threshold: threshold)
    }
}

extension Process {
    // MARK: - Render

    func render(glyphs: [String],
                textFontAttributes: [NSAttributedString.Key: Any],
                dimensions: CGSize,
                width: Int,
                height: Int) -> NSImage
    {
        let rect = CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height)

        let image = NSImage(size: dimensions, flipped: true) { _ in
            NSGraphicsContext.current!.imageInterpolation = .none

            NSColor.white.withAlphaComponent(0.0).setFill()
            rect.fill()

            var x: CGFloat = self.margin
            var y: CGFloat = 0
            for glyph in glyphs {
                if glyph.count == 1 {
                    glyph.draw(at: CGPoint(x: x, y: y - 1), withAttributes: textFontAttributes as [NSAttributedString.Key: Any])
                }

                x = x + CGFloat(width)
                if x > dimensions.width {
                    y = y + CGFloat(height)
                    x = self.margin
                }
            }

            return true
        }
        return image
    }

    func cellSize(glyphs: [String], textFontAttributes: [NSAttributedString.Key: Any]) -> (Int, Int) {
        var tallest: Double = 0
        var widest: Double = 0

        for glyph in glyphs {
            if glyph.count == 1 {
                let size: CGSize = glyph.size(withAttributes: textFontAttributes as [NSAttributedString.Key: Any])
                tallest = max(tallest, size.height)
                widest = max(widest, size.width)
                metaList.append(FontMeta(glyph: glyph, width: Int(size.width + margin)))
            } else {
                metaList.append(FontMeta(glyph: "space", width: 4))
            }
        }

        return (Int(ceil(widest)), Int(ceil(tallest)))
    }
}

extension Process {
    // MARK: - File saving

    func save(
        image fontSheetImage: NSImage,
        width: Int,
        height: Int
    ) {
        let folder = fontFolderURL(at: outputFolderURL,
                                   name: fontSheetFileName)

        if embedded {
            let sampleFontURL = fontSampleFileURL(at: folder,
                                                  size: size,
                                                  weight: weight,
                                                  width: width,
                                                  height: height)

            savePNG(image: fontSheetImage,
                    output: sampleFontURL)
        } else {
            let outputImageURL = fontImageFileURL(at: folder,
                                                  size: size,
                                                  weight: weight,
                                                  width: width,
                                                  height: height)

            savePNG(image: fontSheetImage,
                    output: outputImageURL)
        }

        let outputFontURL = fontFileURL(at: folder,
                                        size: size,
                                        weight: weight,
                                        width: width,
                                        height: height)

        saveFontFile(image: fontSheetImage,
                     metaList: metaList,
                     outputFontURL: outputFontURL,
                     width: width,
                     height: height)
    }

    func savePNG(image: NSImage, output: URL) {
        if let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!) {
            imageRep.hasAlpha = true
            if let pngData = imageRep.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: output)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    func saveFontFile(image: NSImage,
                      metaList: [FontMeta],
                      outputFontURL: URL,
                      width: Int,
                      height: Int)
    {
        var file = ""
        file.append("width=\(width)\n")
        file.append("height=\(height)\n")
        file.append("\n")

        if embedded {
            if let tiffData = image.tiffRepresentation {
                if let bitmap = NSBitmapImageRep(data: tiffData) {
                    if let data = bitmap.representation(using: .png, properties: [:]) {
                        if let base64 = String(data: data.base64EncodedData(), encoding: .utf8) {
                            let dataLength: Int = base64.count
                            file.append("datalen=\(dataLength)\n")
                            file.append("data=\(base64)\n")
                        }
                    }
                }
            }
            file.append("\n")
        }

        for meta in metaList {
            file.append("\(meta.glyph)\t\t\(meta.width)\n")
        }
        file = String(file.dropLast())

        print("\(metaList.count) glyphs written to \(fontSheetFileName) font file at \(outputFontURL.path)")

        do {
            if FileManager.default.fileExists(atPath: outputFontURL.absoluteString) {
                try FileManager.default.removeItem(at: outputFontURL)
            }
            try file.write(to: outputFontURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(outputFontURL.path)
            print(error.localizedDescription)
        }
    }

    // MARK: - File names

    func fontFolderURL(at folder: URL, name: String) -> URL {
        let path = folder.appending(path: name)
        do {
            if !FileManager.default.fileExists(atPath: path.path) {
                print("Creating folder \(path.path)")
                try FileManager.default.createDirectory(atPath: path.path, withIntermediateDirectories: true)
            }
        } catch {
            print(error.localizedDescription)
        }
        return path
    }

    func fontFileURL(at folder: URL,
                     size: CGFloat,
                     weight: String?,
                     width: Int,
                     height: Int) -> URL
    {
        var pathFragment = "\(fontSheetFileName)"

        if let weight {
            pathFragment.append("-\(Int(size))")
            if weight.first == weight.capitalized.first {
                pathFragment.append("-\(weight)")
            } else {
                pathFragment.append("-\(weight.capitalized)")
            }
        }
        pathFragment.append("-\(width)-\(height)")

        pathFragment.append(".fnt")

        return folder.appending(path: pathFragment)
    }

    func fontSampleFileURL(at folder: URL,
                           size: CGFloat,
                           weight: String?,
                           width: Int,
                           height: Int) -> URL
    {
        var pathFragment = "sample-\(fontSheetFileName)"

        if let weight {
            pathFragment.append("-\(Int(size))")
            if weight.first == weight.capitalized.first {
                pathFragment.append("-\(weight)")
            } else {
                pathFragment.append("-\(weight.capitalized)")
            }
        }
        pathFragment.append("-\(width)-\(height)")
        pathFragment.append(".png")

        return folder.appending(path: pathFragment)
    }

    func fontImageFileURL(at folder: URL,
                          size: CGFloat,
                          weight: String?,
                          width: Int,
                          height: Int) -> URL
    {
        var pathFragment = "\(fontSheetFileName)"

        if let weight {
            pathFragment.append("-\(Int(size))")
            if weight.first == weight.capitalized.first {
                pathFragment.append("-\(weight)")
            } else {
                pathFragment.append("-\(weight.capitalized)")
            }
        }

        pathFragment.append("-table-\(width)-\(height)")
        pathFragment.append(".png")

        return folder.appending(path: pathFragment)
    }
}
