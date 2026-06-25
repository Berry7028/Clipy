//
//  PasteboardContent.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Shunsuke Furubayashi on 2026/05/28.
//
//  Copyright © 2015-2026 Clipy Project.
//

import Cocoa
import CryptoKit
import ImageIO
import SwiftHEXColors

struct PasteboardContent: Equatable {
    struct Asset: Equatable {
        let type: NSPasteboard.PasteboardType
        let data: Data
    }

    // MARK: - Properties
    let types: [NSPasteboard.PasteboardType]
    let assets: [Asset]
    let hash: String

    var isOnlyStringType: Bool {
        types == [.string] || types == [.deprecatedString]
    }
    var stringValue: String {
        guard let data = data(for: .string) ?? data(for: .deprecatedString) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    var title: String {
        let title = stringValue
        if !title.isEmpty {
            return title
        }
        if isImageContent {
            return "Image"
        }
        return ""
    }
    var colorCodeImage: NSImage? {
        guard let color = NSColor(hexString: stringValue) else { return nil }
        return NSImage.create(with: color, size: NSSize(width: 20, height: 20))
    }
    var thumbnailImage: NSImage? {
        let defaults = UserDefaults.standard
        let width = max(defaults.integer(forKey: Constants.UserDefaults.thumbnailWidth), 1)
        let height = max(defaults.integer(forKey: Constants.UserDefaults.thumbnailHeight), 1)

        let imageURL = assets.filter { $0.type == .fileURL }
            .compactMap { URL(dataRepresentation: $0.data, relativeTo: nil) }
            .first(where: { ["jpg", "jpeg", "png", "bmp", "tiff"].contains($0.pathExtension.lowercased()) })
        if let imageURL {
            return Self.downsampledImage(url: imageURL, width: width, height: height)
        } else if let data = data(for: .png) ?? data(for: .tiff) ?? data(for: .deprecatedTIFF) {
            return Self.downsampledImage(data: data, width: width, height: height)
        }
        return nil
    }
    var pasteboardItems: [NSPasteboardItem] {
        var countsByType: [NSPasteboard.PasteboardType: Int] = [:]
        // History assets intentionally do not persist the original NSPasteboardItem boundaries.
        // Replaying groups assets by each pasteboard type's occurrence index, which keeps
        // multi-item file writes working without making item boundaries part of the schema.
        return assets
            .filter { $0.type != .deprecatedFilenames }
            .reduce(into: [NSPasteboardItem]()) { items, asset in
                let index = countsByType[asset.type] ?? 0
                countsByType[asset.type] = index + 1
                if !items.indices.contains(index) {
                    items.append(NSPasteboardItem())
                }
                items[index].setData(asset.data, forType: asset.type)
            }
    }

    // MARK: - Initialize
    init?(assets: [Asset]) {
        guard !assets.isEmpty else { return nil }
        self.types = assets.map(\.type)
        self.assets = assets
        var data = Data()
        assets.forEach { asset in
            data.append(value: Data(asset.type.rawValue.utf8))
            data.append(value: asset.data)
        }
        self.hash = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    init?(pasteboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) {
        let itemAssets = pasteboard.pasteboardItems?.compactMap { item -> [Asset]? in
            item.types.filter { types.contains($0) }
                .compactMap { type -> Asset? in
                    guard let data = item.data(forType: type) else { return nil }
                    return Asset(type: type, data: data)
                }
        }
        .flatMap { $0 } ?? []
        // Fall back to the pasteboard root for types that may only be available there,
        // such as .tiff and .deprecatedFilenames.
        let itemAssetTypes = itemAssets.map(\.type)
        let rootAssets = types
            .filter { !itemAssetTypes.contains($0) }
            .compactMap { type -> Asset? in
                guard let data = pasteboard.data(forType: type) else { return nil }
                return Asset(type: type, data: data)
            }
        let assets = (itemAssets + rootAssets).sorted(by: types)
        guard !assets.isEmpty else { return nil }
        self.init(assets: assets)
    }

    init?(image: NSImage) {
        if let data = image.pngRepresentation {
            self.init(assets: [Asset(type: .png, data: data)])
        } else if let data = image.tiffRepresentation {
            self.init(assets: [Asset(type: .tiff, data: data)])
        } else {
            return nil
        }
    }
}

extension PasteboardContent {
    func writeObjects(to pasteboard: NSPasteboard) {
        let pasteboardItems = self.pasteboardItems
        let filenamesAsset = self.assets.first(where: { $0.type == .deprecatedFilenames })

        pasteboard.clearContents()
        // File URLs are normally written as per-item fileURL data.
        // Keep NSFilenamesPboardType on the pasteboard root for legacy history entries
        // and apps that only understand the deprecated filenames flavor.
        if let filenamesAsset {
            pasteboard.setData(filenamesAsset.data, forType: filenamesAsset.type)
        }
        pasteboard.writeObjects(pasteboardItems)
    }
}

// MARK: - Hover Preview
extension PasteboardContent {
    /// A larger image used for the hover preview. Reuses the same downsampling pipeline as the
    /// menu thumbnail, but bounded by `maxPixelSize` on the longest side.
    func previewImage(maxPixelSize: Int) -> NSImage? {
        let imageURL = assets.filter { $0.type == .fileURL }
            .compactMap { URL(dataRepresentation: $0.data, relativeTo: nil) }
            .first(where: { ["jpg", "jpeg", "png", "bmp", "tiff"].contains($0.pathExtension.lowercased()) })
        if let imageURL {
            return Self.downsampledImage(url: imageURL, width: maxPixelSize, height: maxPixelSize)
        } else if let data = data(for: .png) ?? data(for: .tiff) ?? data(for: .deprecatedTIFF) {
            return Self.downsampledImage(data: data, width: maxPixelSize, height: maxPixelSize)
        }
        return nil
    }

    /// Raw PDF data, if the content represents a PDF.
    var pdfData: Data? {
        data(for: .pdf) ?? data(for: .deprecatedPDF)
    }

    /// File URLs carried by the content, if any.
    var fileURLs: [URL] {
        assets.filter { $0.type == .fileURL }
            .compactMap { URL(dataRepresentation: $0.data, relativeTo: nil) }
    }
}

private extension PasteboardContent {
    var isImageContent: Bool {
        assets.contains {
            $0.type == .png || $0.type == .tiff || $0.type == .deprecatedTIFF
        }
    }

    func data(for type: NSPasteboard.PasteboardType) -> Data? {
        assets.first(where: { $0.type == type })?.data
    }

    static func downsampledImage(data: Data, width: Int, height: Int) -> NSImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return downsampledImage(from: imageSource, width: width, height: height)
    }

    static func downsampledImage(url: URL, width: Int, height: Int) -> NSImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        return downsampledImage(from: imageSource, width: width, height: height)
    }

    static func downsampledImage(from imageSource: CGImageSource, width: Int, height: Int) -> NSImage? {
        let maxPixelSize = max(width, height)
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return image.aspectFitImage(CGFloat(width), CGFloat(height))
    }
}

private extension NSImage {
    var pngRepresentation: Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

private extension [PasteboardContent.Asset] {
    func sorted(by types: [NSPasteboard.PasteboardType]) -> Self {
        types.flatMap { type in
            filter { $0.type == type }
        }
    }
}

private extension Data {
    mutating func append(value: Data) {
        var length = UInt64(value.count).bigEndian
        Swift.withUnsafeBytes(of: &length) {
            append(contentsOf: $0)
        }
        append(value)
    }
}
