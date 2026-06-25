//
//  CPYShortcutsPreferenceViewController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/02/26.
//
//  Copyright (c) 2015-2018 Clipy Project.
//

import Cocoa
import KeyHolder
import Magnet
import SwiftUI

final class CPYShortcutsPreferenceViewController: NSViewController {}

struct ShortcutsPreferencePane: View {
    var body: some View {
        PreferenceForm {
            Section(String(localized: "Menu")) {
                ShortcutPreferenceRow(title: String(localized: "Main"), target: .main)
                ShortcutPreferenceRow(title: String(localized: "History"), target: .history)
                ShortcutPreferenceRow(title: String(localized: "Snippet"), target: .snippet)
            }

            Section(String(localized: "History")) {
                ShortcutPreferenceRow(title: String(localized: "Clear History"), target: .clearHistory)
            }
        }
    }
}

private struct ShortcutPreferenceRow: View {
    let title: String
    let target: ShortcutRecordTarget

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ShortcutRecordView(target: target)
                .frame(width: 180, height: 28)
        }
    }
}

private struct ShortcutRecordView: NSViewRepresentable {
    let target: ShortcutRecordTarget

    func makeCoordinator() -> Coordinator {
        Coordinator(target: target)
    }

    func makeNSView(context: Context) -> RecordView {
        let recordView = RecordView(frame: .zero)
        recordView.delegate = context.coordinator
        recordView.keyCombo = target.currentKeyCombo
        return recordView
    }

    func updateNSView(_ nsView: RecordView, context: Context) {
        context.coordinator.target = target
        nsView.delegate = context.coordinator
        nsView.keyCombo = target.currentKeyCombo
    }

    final class Coordinator: NSObject, RecordViewDelegate {
        var target: ShortcutRecordTarget

        init(target: ShortcutRecordTarget) {
            self.target = target
        }

        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
            true
        }

        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
            true
        }

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            target.update(keyCombo)
        }

        func recordViewDidEndRecording(_ recordView: RecordView) {}
    }
}

enum ShortcutRecordTarget {
    case main
    case history
    case snippet
    case clearHistory

    var currentKeyCombo: KeyCombo? {
        switch self {
        case .main:
            return AppEnvironment.current.hotKeyService.mainKeyCombo
        case .history:
            return AppEnvironment.current.hotKeyService.historyKeyCombo
        case .snippet:
            return AppEnvironment.current.hotKeyService.snippetKeyCombo
        case .clearHistory:
            return AppEnvironment.current.hotKeyService.clearHistoryKeyCombo
        }
    }

    func update(_ keyCombo: KeyCombo?) {
        switch self {
        case .main:
            AppEnvironment.current.hotKeyService.change(with: .main, keyCombo: keyCombo)
        case .history:
            AppEnvironment.current.hotKeyService.change(with: .history, keyCombo: keyCombo)
        case .snippet:
            AppEnvironment.current.hotKeyService.change(with: .snippet, keyCombo: keyCombo)
        case .clearHistory:
            AppEnvironment.current.hotKeyService.changeClearHistoryKeyCombo(keyCombo)
        }
    }
}
