//
//  ClipMenuItemView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Copyright © 2015-2026 Clipy Project.
//

import AppKit

/// A custom view used for clipboard-history menu items so the hover preview can be anchored
/// precisely to a row. It reproduces the native menu row appearance (number/title + right-aligned
/// thumbnail + selection highlight). The preview itself is driven by `MenuManager` via
/// `NSMenuDelegate.menu(_:willHighlight:)`, which is a far more stable signal than raw
/// mouse-enter/exit events.
final class ClipMenuItemView: NSView {

    // MARK: - Properties
    let historyID: PasteboardHistory.ID

    private let title: String
    private let thumbnail: NSImage?
    private let appIcon: NSImage?

    private let font = NSFont.menuFont(ofSize: 0)
    private let leftInset: CGFloat = 21
    private let rightInset: CGFloat = 14
    private let textImageSpacing: CGFloat = 8
    private let appIconSize: CGFloat = 16
    private let appIconLeftPad: CGFloat = 6
    private let appIconTextGap: CGFloat = 6

    private var mouseInside = false

    /// The row's frame in screen coordinates, used to position the preview panel.
    var anchorRectOnScreen: NSRect? {
        guard let window else { return nil }
        return window.convertToScreen(convert(bounds, to: nil))
    }

    // MARK: - Initialize
    init(title: String, thumbnail: NSImage?, appIcon: NSImage?, historyID: PasteboardHistory.ID) {
        self.title = title
        self.thumbnail = thumbnail
        self.appIcon = appIcon
        self.historyID = historyID

        let textStart = (appIcon != nil) ? appIconLeftPad + appIconSize + appIconTextGap : leftInset
        let textWidth = (title as NSString).size(withAttributes: [.font: font]).width
        var width = textStart + ceil(textWidth) + rightInset
        var height: CGFloat = 22
        if let thumbnail {
            width += textImageSpacing + thumbnail.size.width
            height = max(height, thumbnail.size.height + 6)
        }
        super.init(frame: NSRect(x: 0, y: 0, width: max(width, 180), height: height))
        autoresizingMask = [.width]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Tracking (visual highlight only)
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        mouseInside = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        mouseInside = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        // Swallow the press so the matching mouseUp is delivered to this view.
    }

    override func mouseUp(with event: NSEvent) {
        guard let item = enclosingMenuItem, let menu = item.menu else { return }
        let index = menu.index(of: item)
        menu.cancelTracking()
        if index >= 0 {
            menu.performActionForItem(at: index)
        }
    }

    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let isHighlighted = mouseInside || (enclosingMenuItem?.isHighlighted ?? false)

        if isHighlighted {
            let selectionRect = bounds.insetBy(dx: 5, dy: 1)
            let path = NSBezierPath(roundedRect: selectionRect, xRadius: 5, yRadius: 5)
            NSColor.selectedContentBackgroundColor.setFill()
            path.fill()
        }

        var textStart = leftInset
        if let appIcon {
            let iconY = (bounds.height - appIconSize) / 2
            appIcon.draw(
                in: NSRect(x: appIconLeftPad, y: iconY, width: appIconSize, height: appIconSize),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
            textStart = appIconLeftPad + appIconSize + appIconTextGap
        }

        var textMaxX = bounds.width - rightInset
        if let thumbnail {
            let size = thumbnail.size
            let imageX = bounds.width - rightInset - size.width
            let imageY = (bounds.height - size.height) / 2
            thumbnail.draw(
                in: NSRect(x: imageX, y: imageY, width: size.width, height: size.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
            textMaxX = imageX - textImageSpacing
        }

        let textColor: NSColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: title, attributes: attributes)
        let textHeight = attributed.size().height
        let textRect = NSRect(
            x: textStart,
            y: (bounds.height - textHeight) / 2,
            width: max(0, textMaxX - textStart),
            height: textHeight
        )
        attributed.draw(with: textRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
    }
}
