//
//  ClipPreviewController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2026 Clipy Project.
//

import AppKit
import Dependencies
import PDFKit
import SwiftHEXColors

/// Shows a floating preview panel next to the highlighted history menu row.
/// The panel is placed to the right of the row, or to the left when it would run past
/// the right edge of the screen.
final class ClipPreviewController {

    // MARK: - Properties
    @Dependency(\.pasteboardHistoryRepository)
    private var pasteboardHistoryRepository

    private var panel: NSPanel?
    private var currentID: PasteboardHistory.ID?
    private var hideTimer: Timer?

    // Layout constants
    private let maxImagePixelSize = 600
    private let maxContentSize = NSSize(width: 520, height: 460)
    private let textWidth: CGFloat = 380
    private let contentInset: CGFloat = 12
    private let gap: CGFloat = 8

    // MARK: - Public
    /// Show (or update) the preview for the given history row.
    /// - Parameters:
    ///   - id: The history record id.
    ///   - anchorRect: The row's frame in screen coordinates.
    func show(id: PasteboardHistory.ID, anchorRect: NSRect) {
        cancelHideTimer()
        // Already showing this row: keep it as-is (avoids rebuilding/flicker on repeated highlights).
        if id == currentID, let panel, panel.isVisible {
            return
        }
        guard let content = pasteboardHistoryRepository.fetchContent(id: id) else {
            hide()
            return
        }
        guard let contentView = makeContentView(for: content) else {
            hide()
            return
        }
        currentID = id

        let card = makeCard(wrapping: contentView)
        // Capture the size before installing the card: assigning `contentView` resizes the card to the
        // panel's current (possibly zero) content rect, so the content size must be applied first.
        let cardSize = card.frame.size
        let panel = preparedPanel()
        panel.setContentSize(cardSize)
        panel.contentView = card
        panel.setFrameOrigin(origin(for: cardSize, anchorRect: anchorRect))
        panel.orderFrontRegardless()
    }

    /// Hide the preview after a short delay so moving between two previewable rows does not flicker.
    func scheduleHide() {
        cancelHideTimer()
        let timer = Timer(timeInterval: 0.18, repeats: false) { [weak self] _ in
            self?.hide()
        }
        // Add to common + event-tracking modes so it fires while a menu is being tracked.
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.add(timer, forMode: .eventTracking)
        hideTimer = timer
    }

    /// Hide the preview immediately.
    func hide() {
        cancelHideTimer()
        currentID = nil
        panel?.orderOut(nil)
    }

    // MARK: - Panel
    private func preparedPanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        // The preview is purely informational and must never steal mouse events from the menu.
        panel.ignoresMouseEvents = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.panel = panel
        return panel
    }

    private func makeCard(wrapping contentView: NSView) -> NSView {
        let size = NSSize(
            width: contentView.frame.width + contentInset * 2,
            height: contentView.frame.height + contentInset * 2
        )
        let card = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        card.material = .menu
        card.state = .active
        card.blendingMode = .behindWindow
        card.wantsLayer = true
        card.layer?.cornerRadius = 10
        card.layer?.masksToBounds = true
        contentView.frame.origin = NSPoint(x: contentInset, y: contentInset)
        card.addSubview(contentView)
        return card
    }

    private func origin(for size: NSSize, anchorRect: NSRect) -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.intersects(anchorRect) }
            ?? NSScreen.main
        let visible = screen?.visibleFrame ?? anchorRect

        var originX = anchorRect.maxX + gap
        if originX + size.width > visible.maxX {
            // Not enough room on the right; place on the left of the row.
            originX = anchorRect.minX - gap - size.width
        }
        originX = max(visible.minX, min(originX, visible.maxX - size.width))

        // Align the preview's top edge with the row's top edge.
        var originY = anchorRect.maxY - size.height
        originY = max(visible.minY, min(originY, visible.maxY - size.height))

        return NSPoint(x: originX, y: originY)
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    // MARK: - Content
    private func makeContentView(for content: PasteboardContent) -> NSView? {
        // Image (raw image data or an image file URL)
        if let image = content.previewImage(maxPixelSize: maxImagePixelSize) {
            return makeImageView(image)
        }
        // PDF (first page)
        if let pdfData = content.pdfData, let image = pdfFirstPageImage(from: pdfData) {
            return makeImageView(image)
        }
        // File list
        let fileURLs = content.fileURLs
        if !fileURLs.isEmpty {
            let list = fileURLs.map { $0.path }.joined(separator: "\n")
            return makeTextView(list)
        }
        // Color code
        let trimmed = content.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed.count <= 9, let color = NSColor(hexString: trimmed) {
            return makeColorView(color, hex: trimmed)
        }
        // Plain text
        let text = content.stringValue
        guard !text.isEmpty else { return nil }
        return makeTextView(text)
    }

    private func makeImageView(_ image: NSImage) -> NSView {
        var size = image.size
        let scale = min(1, min(maxContentSize.width / size.width, maxContentSize.height / size.height))
        size = NSSize(width: max(1, size.width * scale), height: max(1, size.height * scale))
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }

    private func makeColorView(_ color: NSColor, hex: String) -> NSView {
        let size = NSSize(width: 220, height: 160)
        let container = NSView(frame: NSRect(origin: .zero, size: size))

        let labelHeight: CGFloat = 22
        let swatch = NSView(frame: NSRect(x: 0, y: labelHeight + 6, width: size.width, height: size.height - labelHeight - 6))
        swatch.wantsLayer = true
        swatch.layer?.backgroundColor = color.cgColor
        swatch.layer?.cornerRadius = 6
        swatch.layer?.borderWidth = 1
        swatch.layer?.borderColor = NSColor.separatorColor.cgColor
        container.addSubview(swatch)

        let label = NSTextField(labelWithString: hex)
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        label.frame = NSRect(x: 0, y: 0, width: size.width, height: labelHeight)
        container.addSubview(label)

        return container
    }

    private func makeTextView(_ string: String) -> NSView {
        // Use a lightweight wrapping NSTextField (label) instead of NSTextView. Instantiating an
        // NSTextView during menu tracking spins the run loop and causes a spurious mouseExited that
        // dismisses the preview immediately.
        let maxChars = 2000
        let display = string.count > maxChars ? String(string.prefix(maxChars)) + "…" : string

        let label = NSTextField(wrappingLabelWithString: display)
        label.isSelectable = false
        label.isEditable = false
        label.drawsBackground = false
        label.isBordered = false
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.preferredMaxLayoutWidth = textWidth - 8

        let fitting = label.fittingSize
        let height = min(max(fitting.height, 20), maxContentSize.height)
        label.frame = NSRect(x: 0, y: 0, width: textWidth, height: height)
        return label
    }

    private func pdfFirstPageImage(from data: Data) -> NSImage? {
        guard let document = PDFDocument(data: data), let page = document.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(maxContentSize.width / bounds.width, maxContentSize.height / bounds.height, 1)
        return page.thumbnail(of: NSSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
    }
}
