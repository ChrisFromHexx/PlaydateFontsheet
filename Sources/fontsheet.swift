//
//  fontsheet.swift
//
//
//  Created by Chris Samuels (Hexagonal Studios Limited) on 06/07/2024.
//
import ArgumentParser

@main
struct fontsheet: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Creates PlayDate format fonts (.fnt) from the fonts you have installed to the 'Font Book' app.",
        discussion: """
        Used as the basis for creating your own unique custom PlayDate fonts.              
        Some fettling with tools like Caps (https://play.date/caps/) will be required to perfectly tune the font files.
        """
    )

    @Argument(help: "Glyph order file")
    var glyphFile: String

    @Option(name: [.short, .customLong("output")], help: "Output directory")
    var outputFolder: String

    @Option(name: [.short, .customLong("name")], help: "Name of output font sheet")
    var name: String

    @Option(name: [.short, .customLong("font")], help: "Name of font to render")
    var font: String

    @Option(name: [.short, .customLong("size")], help: "Point size of font to render")
    var size: Float

    @Option(name: [.short, .customLong("weight")], help: "Weight name of font [Regular,Bold,…] (optional)")
    var weight: String?

    @Option(name: [.short, .customLong("threshold")], help: "Gradient selection point between black/white pixel boundaries. [0.0 - 1.0], default 0.5 (optional)")
    var threshold: Float?

    @Flag(name: [.short, .customLong("embedded")], help: "Embed font image in .fnt file")
    var embedded = false

    mutating func run() throws {
        if let process = Process(fontSheetFileName: name,
                                 fontName: font,
                                 glyphFile: glyphFile,
                                 outputFolder: outputFolder,
                                 size: size,
                                 weight: weight,
                                 threshold: threshold,
                                 embedded: embedded)
        {
            process.run()
        }
    }
}
