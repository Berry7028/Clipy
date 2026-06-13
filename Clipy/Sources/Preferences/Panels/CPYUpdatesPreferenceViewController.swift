//
//  CPYUpdatesPreferenceViewController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/03/17.
//
//  Copyright (c) 2015-2018 Clipy Project.
//

import Cocoa
import Combine
import Sparkle
import SwiftUI

final class CPYUpdatesPreferenceViewController: NSViewController {}

struct UpdatesPreferencePane: View {
    @AppStorage(Constants.Update.enableAutomaticCheck)
    private var enableAutomaticCheck = true
    @AppStorage(Constants.Update.checkInterval)
    private var checkInterval = 86_400
    @StateObject private var model = UpdatesPreferenceModel()

    var body: some View {
        PreferenceForm {
            Section(String(localized: "Version")) {
                HStack {
                    Text(String(localized: "Current version"))
                    Spacer()
                    Text(model.version)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(String(localized: "Last update check"))
                    Spacer()
                    Text(model.lastUpdateCheckDateText)
                        .foregroundStyle(.secondary)
                }

                Button {
                    model.checkForUpdates()
                } label: {
                    Label(String(localized: "Check Now"), systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section(String(localized: "Automatic Updates")) {
                Toggle(String(localized: "Automatically check for updates:"), isOn: $enableAutomaticCheck)

                Picker(String(localized: "Check interval"), selection: $checkInterval) {
                    Text(String(localized: "Daily")).tag(86_400)
                    Text(String(localized: "Weekly")).tag(604_800)
                    Text(String(localized: "Monthly")).tag(2_592_000)
                }
                .pickerStyle(.menu)
                .disabled(!enableAutomaticCheck)
            }
        }
        .onChange(of: checkInterval) { newValue in
            model.updateCheckInterval(newValue)
        }
    }
}

private final class UpdatesPreferenceModel: ObservableObject {
    @Published private(set) var lastUpdateCheckDate: Date?

    let version = "v\(Bundle.main.appVersion ?? "")"
    private var cancellables: Set<AnyCancellable> = []

    var lastUpdateCheckDateText: String {
        guard let lastUpdateCheckDate else {
            return String(localized: "Never")
        }
        return lastUpdateCheckDate.formatted(date: .abbreviated, time: .shortened)
    }

    init() {
        updaterController?.updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastUpdateCheckDate, on: self)
            .store(in: &cancellables)
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    func updateCheckInterval(_ interval: Int) {
        updaterController?.updater.updateCheckInterval = TimeInterval(interval)
    }

    private var updaterController: SPUStandardUpdaterController? {
        (NSApp.delegate as? AppDelegate)?.updaterController
    }
}
