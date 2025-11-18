//
//  ClipPreviewView.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Claude on 2025/11/18.
//
//  Copyright © 2015-2018 Clipy Project.
//

import SwiftUI
import RealmSwift

@available(macOS 15.0, *)
struct ClipPreviewView: View {
    let clip: CPYClip
    @State private var isFavorite: Bool
    @Environment(\.dismiss) private var dismiss

    init(clip: CPYClip) {
        self.clip = clip
        self._isFavorite = State(initialValue: clip.isFavorite)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Clipboard Preview")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                .help(isFavorite ? "Remove from favorites" : "Add to favorites")
            }

            Divider()

            // Content Preview
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Type indicator
                    HStack {
                        Image(systemName: iconForType)
                            .foregroundColor(.accentColor)
                        Text(typeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Content
                    if clip.primaryType.contains("tiff") || clip.primaryType.contains("png") {
                        imagePreview
                    } else {
                        textPreview
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                        Text("Created: \(formattedDate)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if !clip.dataHash.isEmpty {
                            Text("Hash: \(clip.dataHash.prefix(8))...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Actions
            HStack {
                Spacer()

                Button("Copy") {
                    copyToClipboard()
                }
                .keyboardShortcut(.return, modifiers: .command)

                Button("Paste") {
                    pasteContent()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])

                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imagePreview: some View {
        if !clip.thumbnailPath.isEmpty {
            AsyncImage(url: URL(fileURLWithPath: clip.thumbnailPath)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var textPreview: some View {
        Text(clip.title)
            .textSelection(.enabled)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties

    private var iconForType: String {
        if clip.primaryType.contains("tiff") || clip.primaryType.contains("png") {
            return "photo"
        } else if clip.primaryType.contains("pdf") {
            return "doc.richtext"
        } else if clip.primaryType.contains("file") {
            return "folder"
        } else if clip.isColorCode {
            return "paintpalette"
        } else {
            return "doc.text"
        }
    }

    private var typeDescription: String {
        if clip.primaryType.contains("tiff") || clip.primaryType.contains("png") {
            return "Image"
        } else if clip.primaryType.contains("pdf") {
            return "PDF Document"
        } else if clip.primaryType.contains("file") {
            return "Files"
        } else if clip.isColorCode {
            return "Color Code"
        } else {
            return "Text"
        }
    }

    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(clip.updateTime))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func toggleFavorite() {
        let realm = try! Realm()
        try? realm.write {
            clip.isFavorite.toggle()
            if clip.isFavorite {
                let maxIndex = realm.objects(CPYClip.self)
                    .filter("isFavorite == true")
                    .max(ofProperty: "favoriteIndex") as Int? ?? -1
                clip.favoriteIndex = maxIndex + 1
            }
        }
        isFavorite = clip.isFavorite
    }

    private func copyToClipboard() {
        AppEnvironment.current.pasteService.copyToPasteboard(with: clip.title)
    }

    private func pasteContent() {
        AppEnvironment.current.pasteService.paste(with: clip)
    }
}

// MARK: - Preview Window Controller

@available(macOS 15.0, *)
@MainActor
final class ClipPreviewWindowController: NSWindowController {
    static let shared = ClipPreviewWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard Preview"
        window.level = .floating
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(clip: CPYClip) {
        let contentView = ClipPreviewView(clip: clip)
        window?.contentView = NSHostingView(rootView: contentView)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
