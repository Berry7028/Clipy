//
//  CPYPreferencesWindowController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/02/25.
//
//  Copyright (c) 2015-2018 Clipy Project.
//

import Cocoa
import SwiftUI

final class CPYPreferencesWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = CPYPreferencesWindowController()

    // MARK: - Initialize
    init() {
        let hostingController = NSHostingController(rootView: CPYPreferencesView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "Preferences")
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 580, height: 420)
        window.setContentSize(NSSize(width: 640, height: 560))
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Window Life Cycle
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.centerIfNeeded()
        window?.orderFrontRegardless()
    }
}

// MARK: - NSWindow Delegate
extension CPYPreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window, !window.makeFirstResponder(window) {
            window.endEditing(for: nil)
        }
        NSApp.deactivate()
    }
}

private extension NSWindow {
    func centerIfNeeded() {
        guard frame.origin == .zero else { return }
        center()
    }
}

struct CPYPreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferencePane()
                .tabItem { Label(String(localized: "General"), systemImage: "gearshape") }

            MenuPreferencePane()
                .tabItem { Label(String(localized: "Menu"), systemImage: "menubar.rectangle") }

            ClipboardTypesPreferencePane()
                .tabItem { Label(String(localized: "Type"), systemImage: "doc.on.clipboard") }

            ExcludedApplicationsPreferencePane()
                .tabItem { Label(String(localized: "Exclude"), systemImage: "app.badge") }

            ShortcutsPreferencePane()
                .tabItem { Label(String(localized: "Shortcuts"), systemImage: "keyboard") }

            UpdatesPreferencePane()
                .tabItem { Label(String(localized: "Updates"), systemImage: "arrow.triangle.2.circlepath") }

            BetaPreferencePane()
                .tabItem { Label(String(localized: "Beta"), systemImage: "testtube.2") }
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 640, minHeight: 420, idealHeight: 560)
    }
}

struct PreferenceForm<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

struct GeneralPreferencePane: View {
    @AppStorage(Constants.UserDefaults.loginItem)
    private var loginItem = false
    @AppStorage(Constants.UserDefaults.inputPasteCommand)
    private var inputPasteCommand = true
    @AppStorage(Constants.UserDefaults.collectCrashReport)
    private var collectCrashReport = true
    @AppStorage(Constants.UserDefaults.maxHistorySize)
    private var maxHistorySize = 30
    @AppStorage(Constants.UserDefaults.reorderClipsAfterPasting)
    private var reorderClipsAfterPasting = true
    @AppStorage(Constants.UserDefaults.showStatusItem)
    private var showStatusItem = 1

    var body: some View {
        PreferenceForm {
            Section(String(localized: "Behavior")) {
                Toggle(String(localized: "Launch on Login"), isOn: $loginItem)
                Toggle(String(localized: "Input \"⌘ + V\" after menu item selection"), isOn: $inputPasteCommand)
                Toggle(String(localized: "Send crash report and error log (reflected at the next launch)"), isOn: $collectCrashReport)
            }

            Section(String(localized: "Clipboard History")) {
                IntegerStepperRow(
                    title: String(localized: "Max clipboard history size:"),
                    value: $maxHistorySize,
                    range: 1...10_000,
                    suffix: String(localized: "items")
                )

                Picker(String(localized: "Sort history order by:"), selection: $reorderClipsAfterPasting) {
                    Text(String(localized: "Date Created")).tag(false)
                    Text(String(localized: "Last Used")).tag(true)
                }
                .pickerStyle(.menu)
            }

            Section(String(localized: "Appearance")) {
                Picker(String(localized: "Status Bar icon style:"), selection: $showStatusItem) {
                    Text(String(localized: "None")).tag(MenuManager.StatusType.none.rawValue)
                    Text(String(localized: "Black")).tag(MenuManager.StatusType.black.rawValue)
                    Text(String(localized: "White")).tag(MenuManager.StatusType.white.rawValue)
                }
                .pickerStyle(.menu)
            }
        }
    }
}

struct MenuPreferencePane: View {
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInline)
    private var numberOfItemsPlaceInline = 0
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInsideFolder)
    private var numberOfItemsPlaceInsideFolder = 10
    @AppStorage(Constants.UserDefaults.maxMenuItemTitleLength)
    private var maxMenuItemTitleLength = 20
    @AppStorage(Constants.UserDefaults.showIconInTheMenu)
    private var showIconInTheMenu = true
    @AppStorage(Constants.UserDefaults.menuItemsAreMarkedWithNumbers)
    private var menuItemsAreMarkedWithNumbers = true
    @AppStorage(Constants.UserDefaults.menuItemsTitleStartWithZero)
    private var menuItemsTitleStartWithZero = false
    @AppStorage(Constants.UserDefaults.addNumericKeyEquivalents)
    private var addNumericKeyEquivalents = false
    @AppStorage(Constants.UserDefaults.copySameHistory)
    private var copySameHistory = true
    @AppStorage(Constants.UserDefaults.overwriteSameHistory)
    private var overwriteSameHistory = true
    @AppStorage(Constants.UserDefaults.addClearHistoryMenuItem)
    private var addClearHistoryMenuItem = true
    @AppStorage(Constants.UserDefaults.showAlertBeforeClearHistory)
    private var showAlertBeforeClearHistory = true
    @AppStorage(Constants.UserDefaults.showToolTipOnMenuItem)
    private var showToolTipOnMenuItem = true
    @AppStorage(Constants.UserDefaults.maxLengthOfToolTip)
    private var maxLengthOfToolTip = 200
    @AppStorage(Constants.UserDefaults.showImageInTheMenu)
    private var showImageInTheMenu = true
    @AppStorage(Constants.UserDefaults.showColorPreviewInTheMenu)
    private var showColorPreviewInTheMenu = true
    @AppStorage(Constants.UserDefaults.thumbnailWidth)
    private var thumbnailWidth = 100
    @AppStorage(Constants.UserDefaults.thumbnailHeight)
    private var thumbnailHeight = 32

    var body: some View {
        PreferenceForm {
            Section(String(localized: "History Menu")) {
                IntegerStepperRow(
                    title: String(localized: "Number of items place inline:"),
                    value: $numberOfItemsPlaceInline,
                    range: 0...100,
                    suffix: String(localized: "items")
                )
                IntegerStepperRow(
                    title: String(localized: "Number of items place inside a folder:"),
                    value: $numberOfItemsPlaceInsideFolder,
                    range: 1...100,
                    suffix: String(localized: "items")
                )
                IntegerStepperRow(
                    title: String(localized: "Number of characters in the menu:"),
                    value: $maxMenuItemTitleLength,
                    range: 3...500,
                    suffix: String(localized: "chars")
                )
            }

            Section(String(localized: "Menu Items")) {
                Toggle(String(localized: "Display icons in menu items"), isOn: $showIconInTheMenu)
                Toggle(String(localized: "Mark menu items with numbers"), isOn: $menuItemsAreMarkedWithNumbers)
                Toggle(String(localized: "Menu items' title starts with 0"), isOn: $menuItemsTitleStartWithZero)
                    .disabled(!menuItemsAreMarkedWithNumbers)
                Toggle(String(localized: "Add key equivalents to numeric keys"), isOn: $addNumericKeyEquivalents)
            }

            Section(String(localized: "Duplicate History")) {
                Toggle(String(localized: "Place already copied history at the top"), isOn: $copySameHistory)
                Toggle(String(localized: "Move instead of copying (removes the older one from the list)"), isOn: $overwriteSameHistory)
                    .disabled(!copySameHistory)
            }

            Section(String(localized: "Clear History")) {
                Toggle(String(localized: "Add a menu item to clear clipboard history"), isOn: $addClearHistoryMenuItem)
                Toggle(String(localized: "Show alert panel before clear history"), isOn: $showAlertBeforeClearHistory)
                    .disabled(!addClearHistoryMenuItem)
            }

            Section(String(localized: "Tool Tips")) {
                Toggle(String(localized: "Show tool tip on a menu item"), isOn: $showToolTipOnMenuItem)
                IntegerStepperRow(
                    title: String(localized: "Max length of tool tip string:"),
                    value: $maxLengthOfToolTip,
                    range: 1...10_000,
                    suffix: String(localized: "chars")
                )
                .disabled(!showToolTipOnMenuItem)
            }

            Section(String(localized: "Image Previews")) {
                Toggle(String(localized: "Show Image"), isOn: $showImageInTheMenu)
                Toggle(String(localized: "Show color code preview"), isOn: $showColorPreviewInTheMenu)
                IntegerStepperRow(
                    title: String(localized: "Thumbnail width:"),
                    value: $thumbnailWidth,
                    range: 16...512,
                    suffix: String(localized: "px")
                )
                .disabled(!showImageInTheMenu)
                IntegerStepperRow(
                    title: String(localized: "Thumbnail height:"),
                    value: $thumbnailHeight,
                    range: 16...512,
                    suffix: String(localized: "px")
                )
                .disabled(!showImageInTheMenu)
            }
        }
    }
}

struct IntegerStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Stepper(value: $value, in: range) {
                Text("\(value) \(suffix)")
                    .monospacedDigit()
                    .frame(minWidth: 92, alignment: .trailing)
            }
        }
    }
}
