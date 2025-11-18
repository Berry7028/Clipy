//
//  QuickAccessWidget.swift
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
struct QuickAccessWidget: View {
    @State private var recentClips: [CPYClip] = []
    @State private var favorites: [CPYClip] = []
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.accentColor)
                    .imageScale(.large)

                Text("Quick Access")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: openFullApp) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
            }

            Divider()

            // Favorites Section
            if !favorites.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Favorites", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)

                    ForEach(favorites.prefix(3), id: \.dataHash) { clip in
                        QuickClipRow(clip: clip)
                    }
                }

                Divider()
            }

            // Recent Items
            VStack(alignment: .leading, spacing: 8) {
                Label("Recent", systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.secondary)

                ForEach(recentClips.prefix(5), id: \.dataHash) { clip in
                    QuickClipRow(clip: clip)
                }
            }

            Spacer()

            // Footer Actions
            HStack {
                Button(action: openSearch) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: openSettings) {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.borderless)
            }
            .font(.caption)
        }
        .padding()
        .frame(width: 300)
        .task {
            await loadData()
        }
    }

    // MARK: - Subviews

    private func QuickClipRow(clip: CPYClip) -> some View {
        Button(action: {
            pasteClip(clip)
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconForClip(clip))
                    .foregroundColor(.accentColor)
                    .frame(width: 16)

                Text(clip.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if clip.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .imageScale(.small)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func iconForClip(_ clip: CPYClip) -> String {
        if clip.primaryType.contains("tiff") || clip.primaryType.contains("png") {
            return "photo"
        } else if clip.primaryType.contains("pdf") {
            return "doc.richtext"
        } else if clip.isColorCode {
            return "paintpalette"
        } else {
            return "doc.text"
        }
    }

    private func loadData() async {
        let realm = try! Realm()

        // Load favorites
        favorites = Array(realm.objects(CPYClip.self)
            .filter("isFavorite == true")
            .sorted(byKeyPath: #keyPath(CPYClip.favoriteIndex), ascending: true)
            .prefix(3))

        // Load recent clips
        recentClips = Array(realm.objects(CPYClip.self)
            .sorted(byKeyPath: #keyPath(CPYClip.updateTime), ascending: false)
            .prefix(5))
    }

    private func pasteClip(_ clip: CPYClip) {
        AppEnvironment.current.pasteService.paste(with: clip)
    }

    private func openSearch() {
        CPYSearchWindowController.shared.show()
    }

    private func openSettings() {
        NSApp.sendAction(#selector(AppDelegate.showPreferenceWindow), to: nil, from: nil)
    }

    private func openFullApp() {
        NSApp.sendAction(#selector(AppDelegate.showPreferenceWindow), to: nil, from: nil)
    }
}

// MARK: - Quick Access Popover

@available(macOS 15.0, *)
@MainActor
final class QuickAccessPopover {
    static let shared = QuickAccessPopover()

    private var popover: NSPopover?

    private init() {}

    func show(from button: NSStatusBarButton) {
        if popover == nil {
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 300, height: 400)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: QuickAccessWidget())
            self.popover = popover
        }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func close() {
        popover?.performClose(nil)
    }
}
