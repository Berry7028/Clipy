//
//  CPYExcludeAppPreferenceViewController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/08/08.
//
//  Copyright (c) 2015-2018 Clipy Project.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

final class CPYExcludeAppPreferenceViewController: NSViewController {}

struct ExcludedApplicationsPreferencePane: View {
    @State private var applications = AppEnvironment.current.excludeAppService.applications
    @State private var selectedIdentifier: String?

    var body: some View {
        PreferenceForm {
            Section(String(localized: "Exclude these applications:")) {
                if applications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text(String(localized: "No excluded applications"))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    List(selection: $selectedIdentifier) {
                        ForEach(applications, id: \.identifier) { app in
                            Text(app.name)
                                .tag(app.identifier)
                        }
                    }
                    .frame(minHeight: 220)
                }

                HStack {
                    Button {
                        addApplications()
                    } label: {
                        Label(String(localized: "Add"), systemImage: "plus")
                    }

                    Button {
                        deleteSelectedApplication()
                    } label: {
                        Label(String(localized: "Remove"), systemImage: "minus")
                    }
                    .disabled(selectedIdentifier == nil)

                    Spacer()
                }
            }
        }
    }
}

private extension ExcludedApplicationsPreferencePane {
    func addApplications() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.applicationBundle]
        openPanel.allowsMultipleSelection = true
        openPanel.resolvesAliases = true
        openPanel.prompt = String(localized: "Add")

        let directories = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)
        let basePath = directories.first ?? NSHomeDirectory()
        openPanel.directoryURL = URL(fileURLWithPath: basePath)

        guard openPanel.runModal() == .OK else { return }

        openPanel.urls.forEach { url in
            guard let bundle = Bundle(url: url),
                  let info = bundle.infoDictionary as? [String: AnyObject],
                  let appInfo = CPYAppInfo(info: info) else { return }
            AppEnvironment.current.excludeAppService.add(with: appInfo)
        }
        reloadApplications()
    }

    func deleteSelectedApplication() {
        guard let selectedIdentifier,
              let app = applications.first(where: { $0.identifier == selectedIdentifier }) else {
            NSSound.beep()
            return
        }
        AppEnvironment.current.excludeAppService.delete(with: app)
        self.selectedIdentifier = nil
        reloadApplications()
    }

    func reloadApplications() {
        applications = AppEnvironment.current.excludeAppService.applications
    }
}
