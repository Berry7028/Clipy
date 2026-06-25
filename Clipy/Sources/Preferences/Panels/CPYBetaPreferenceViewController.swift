//
//  CPYBetaPreferenceViewController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/06/28.
//
//  Copyright (c) 2015-2018 Clipy Project.
//

import Cocoa
import SwiftUI

final class CPYBetaPreferenceViewController: NSViewController {}

struct BetaPreferencePane: View {
    @AppStorage(Constants.Beta.pastePlainText)
    private var pastePlainText = true
    @AppStorage(Constants.Beta.pastePlainTextModifier)
    private var pastePlainTextModifier = 0
    @AppStorage(Constants.Beta.deleteHistory)
    private var deleteHistory = false
    @AppStorage(Constants.Beta.deleteHistoryModifier)
    private var deleteHistoryModifier = 0
    @AppStorage(Constants.Beta.pasteAndDeleteHistory)
    private var pasteAndDeleteHistory = false
    @AppStorage(Constants.Beta.pasteAndDeleteHistoryModifier)
    private var pasteAndDeleteHistoryModifier = 0
    @AppStorage(Constants.Beta.observerScreenshot)
    private var observerScreenshot = false

    var body: some View {
        PreferenceForm {
            Section(String(localized: "Action")) {
                Toggle(String(localized: "Paste as PlainText"), isOn: $pastePlainText)
                ModifierPicker(selection: $pastePlainTextModifier)
                    .disabled(!pastePlainText)

                Toggle(String(localized: "Delete history"), isOn: $deleteHistory)
                ModifierPicker(selection: $deleteHistoryModifier)
                    .disabled(!deleteHistory)

                Toggle(String(localized: "Paste and delete history"), isOn: $pasteAndDeleteHistory)
                ModifierPicker(selection: $pasteAndDeleteHistoryModifier)
                    .disabled(!pasteAndDeleteHistory)
            }

            Section(String(localized: "Screenshot")) {
                Toggle(String(localized: "Save screenshots in history"), isOn: $observerScreenshot)
            }

            Text(String(localized: "Beta settings might be moved to a different pane in future versions."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ModifierPicker: View {
    @Binding var selection: Int

    var body: some View {
        Picker(String(localized: "Modifier"), selection: $selection) {
            Text(String(localized: "Command")).tag(0)
            Text(String(localized: "Shift")).tag(1)
            Text(String(localized: "Control")).tag(2)
            Text(String(localized: "Alt")).tag(3)
        }
        .pickerStyle(.menu)
    }
}
