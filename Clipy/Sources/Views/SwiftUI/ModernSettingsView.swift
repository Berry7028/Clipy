//
//  ModernSettingsView.swift
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

@available(macOS 15.0, *)
struct ModernSettingsView: View {
    @AppStorage(Constants.UserDefaults.maxHistorySize)
    private var maxHistorySize = 30

    @AppStorage(Constants.UserDefaults.showStatusItem)
    private var showStatusItem = 1

    @AppStorage(Constants.UserDefaults.loginItem)
    private var launchAtLogin = false

    @AppStorage(Constants.UserDefaults.addClearHistoryMenuItem)
    private var showClearHistoryItem = true

    @AppStorage(Constants.UserDefaults.reorderClipsAfterPasting)
    private var reorderAfterPasting = false

    @AppStorage(Constants.UserDefaults.showImageInTheMenu)
    private var showImagesInMenu = true

    @AppStorage(Constants.UserDefaults.maxMenuItemTitleLength)
    private var maxTitleLength = 20

    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case appearance = "Appearance"
        case shortcuts = "Shortcuts"
        case advanced = "Advanced"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gear"
            case .appearance: return "paintbrush"
            case .shortcuts: return "command"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                maxHistorySize: $maxHistorySize,
                launchAtLogin: $launchAtLogin,
                showClearHistoryItem: $showClearHistoryItem,
                reorderAfterPasting: $reorderAfterPasting
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(SettingsTab.general)

            AppearanceSettingsView(
                showStatusItem: $showStatusItem,
                showImagesInMenu: $showImagesInMenu,
                maxTitleLength: $maxTitleLength
            )
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }
            .tag(SettingsTab.appearance)

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(SettingsTab.shortcuts)

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(SettingsTab.advanced)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - General Settings

@available(macOS 15.0, *)
struct GeneralSettingsView: View {
    @Binding var maxHistorySize: Int
    @Binding var launchAtLogin: Bool
    @Binding var showClearHistoryItem: Bool
    @Binding var reorderAfterPasting: Bool

    var body: some View {
        Form {
            Section {
                LabeledContent("Maximum History Size:") {
                    Stepper("\(maxHistorySize) items", value: $maxHistorySize, in: 10...1000, step: 10)
                        .frame(width: 200)
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)

                Toggle("Show Clear History Menu Item", isOn: $showClearHistoryItem)

                Toggle("Move Recently Pasted to Top", isOn: $reorderAfterPasting)
            } header: {
                Text("General")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Clipy")
                        .font(.headline)

                    Text("Version 2.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Link("Visit Website", destination: URL(string: "https://clipy-app.com")!)
                        .font(.subheadline)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings

@available(macOS 15.0, *)
struct AppearanceSettingsView: View {
    @Binding var showStatusItem: Int
    @Binding var showImagesInMenu: Bool
    @Binding var maxTitleLength: Int

    var body: some View {
        Form {
            Section {
                LabeledContent("Menu Bar Icon:") {
                    Picker("", selection: $showStatusItem) {
                        Text("None").tag(0)
                        Text("Black").tag(1)
                        Text("White").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                Toggle("Show Images in Menu", isOn: $showImagesInMenu)

                LabeledContent("Maximum Title Length:") {
                    Stepper("\(maxTitleLength) characters", value: $maxTitleLength, in: 10...200, step: 5)
                        .frame(width: 250)
                }
            } header: {
                Text("Appearance")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.headline)

                    Text("Changes will be reflected in the menu immediately")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Shortcuts Settings

@available(macOS 15.0, *)
struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    ShortcutRow(
                        title: "Main Menu",
                        shortcut: "⌘⇧V",
                        description: "Show clipboard history menu"
                    )

                    ShortcutRow(
                        title: "Search",
                        shortcut: "⌘F",
                        description: "Open search window"
                    )

                    ShortcutRow(
                        title: "Snippets",
                        shortcut: "⌘⇧B",
                        description: "Show snippets menu"
                    )

                    Divider()

                    Text("Note: Shortcuts can be customized in the legacy preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Keyboard Shortcuts")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

@available(macOS 15.0, *)
struct ShortcutRow: View {
    let title: String
    let shortcut: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

// MARK: - Advanced Settings

@available(macOS 15.0, *)
struct AdvancedSettingsView: View {
    @State private var showingClearAlert = false

    var body: some View {
        Form {
            Section {
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("Clear All History", systemImage: "trash")
                }
                .alert("Clear All History?", isPresented: $showingClearAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear", role: .destructive) {
                        clearHistory()
                    }
                } message: {
                    Text("This will permanently delete all clipboard history. This action cannot be undone.")
                }

                Button {
                    resetSettings()
                } label: {
                    Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Data Management")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diagnostics")
                        .font(.headline)

                    Button("View Logs") {
                        openLogs()
                    }

                    Button("Export Settings") {
                        exportSettings()
                    }
                }
            } header: {
                Text("Troubleshooting")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func clearHistory() {
        AppEnvironment.current.clipService.clearAll()
    }

    private func resetSettings() {
        // Reset to defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    private func openLogs() {
        // Open logs directory
        let logsPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! + "/Logs/Clipy"
        NSWorkspace.shared.open(URL(fileURLWithPath: logsPath))
    }

    private func exportSettings() {
        // Export settings
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Clipy-Settings.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            // Export logic here
        }
    }
}

// MARK: - Preview

@available(macOS 15.0, *)
#Preview {
    ModernSettingsView()
}
