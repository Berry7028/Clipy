//
//  CPYTypePreferenceViewController.swift
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
import SwiftUI

final class CPYTypePreferenceViewController: NSViewController {}

struct ClipboardTypesPreferencePane: View {
    @AppStorage(Constants.UserDefaults.ignoreConcealedPasteboardType)
    private var ignoreConcealedPasteboardType = false

    private let defaults = AppEnvironment.current.defaults

    var body: some View {
        PreferenceForm {
            Section(String(localized: "Select clipboard types to store:")) {
                ForEach(PasteboardAvailableType.allCases, id: \.rawValue) { type in
                    Toggle(title(for: type), isOn: storeTypeBinding(for: type))
                }
            }

            Section(String(localized: "Privacy")) {
                Toggle(String(localized: "Ignore clipboard data marked as Concealed"), isOn: $ignoreConcealedPasteboardType)
                Text(String(localized: "For confidential data, such as from password managers."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private extension ClipboardTypesPreferencePane {
    func title(for type: PasteboardAvailableType) -> String {
        switch type {
        case .string:
            return String(localized: "Plain Text")
        case .rtf:
            return String(localized: "Rich Text Format (RTF)")
        case .rtfd:
            return String(localized: "Rich Text Format Directory (RTFD)")
        case .pdf:
            return String(localized: "PDF")
        case .filenames:
            return String(localized: "Filenames")
        case .url:
            return String(localized: "URL")
        case .tiff:
            return String(localized: "Images (PNG/TIFF)")
        }
    }

    func storeTypeBinding(for type: PasteboardAvailableType) -> Binding<Bool> {
        Binding(
            get: {
                storeTypesDictionary()[type.rawValue]?.boolValue ?? true
            },
            set: { isEnabled in
                var storeTypes = storeTypesDictionary()
                storeTypes[type.rawValue] = NSNumber(value: isEnabled)
                defaults.set(storeTypes, forKey: Constants.UserDefaults.storeTypes)
                defaults.synchronize()
            }
        )
    }

    func storeTypesDictionary() -> [String: NSNumber] {
        defaults.object(forKey: Constants.UserDefaults.storeTypes) as? [String: NSNumber] ?? [:]
    }
}
