#!/usr/bin/env swift

import Foundation
import CoreImage
import CoreGraphics
import AppKit

// MARK: - Usage helper

func printUsageAndExit() {
    print("📷 Usage: convert_to_heic.swift <file_path> [compression_ratio]")
    print("🔸 Example: convert_to_heic.swift ./photo.avif 0.88")
    print("🔸 Default compression ratio is 0.8 if not provided.")
}

// MARK: - Parse command line arguments

guard CommandLine.argc >= 2 else {
    printUsageAndExit()
    exit(1)
}

let filePath = CommandLine.arguments[1]
var compressionRatio: CGFloat = 0.8

if CommandLine.argc >= 3 {
    guard let ratio = Double(CommandLine.arguments[2]) else {
        print("⚠️ Invalid compression ratio. Must be a number between 0 and 1.")
        exit(1)
    }
    compressionRatio = ratio
}

// MARK: - Main processing logic

func processFile(_ filePath: String, compressionRatio: CGFloat) {
    let inputURL = URL(fileURLWithPath: filePath)
    let outputURL = inputURL.deletingPathExtension().appendingPathExtension("HEIC")

    guard let sdrImage = CIImage(contentsOf: inputURL, options: [.applyOrientationProperty: true]) else {
        print("❌ Couldn't create SDR image from \(inputURL.path)")
        exit(1)
    }

    guard let hdrImage = CIImage(contentsOf: inputURL, options: [.expandToHDR: true, .applyOrientationProperty: true]) else {
        print("❌ Couldn't load HDR version")
        exit(1)
    }

    print("📸 Processing image at compression: \(compressionRatio)")
    print("🎨 Image Info:")
    print("   📦 Path: \(inputURL.path)")
    print("   🌞 Content Headroom: \(hdrImage.contentHeadroom)")
    print("   🎨 SDR ColorSpace: \(sdrImage.colorSpace?.name as String? ?? "nil")")
    print("   💡 HDR ColorSpace: \(hdrImage.colorSpace?.name as String? ?? "nil")")

    let colorSpace = sdrImage.colorSpace ?? CGColorSpace(name: CGColorSpace.displayP3)!
    let context = CIContext()

    do {
        let options: [CIImageRepresentationOption: Any] = [
            kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compressionRatio,
            .hdrImage: hdrImage as Any
        ]

        try context.writeHEIFRepresentation(of: sdrImage, to: outputURL, format: CIFormat.RGBA8, colorSpace: colorSpace, options: options)

        print("✅ Saved HEIC to: \(outputURL.path)")
    } catch {
        print("💥 Failed to write image: \(error)")
        exit(1)
    }
}

// MARK: - Execute main function

processFile(filePath, compressionRatio: compressionRatio)