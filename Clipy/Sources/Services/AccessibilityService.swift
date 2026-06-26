// 
//  AccessibilityService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
// 
//  Created by Econa77 on 2018/10/03.
// 
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa

final class AccessibilityService {
    // Once accessibility has been confirmed available in this session, remember it.
    // Both AXIsProcessTrustedWithOptions and the focused-application probe can
    // intermittently report "not trusted" for ad-hoc signed builds even after the
    // user has granted permission, which produced spurious permission alerts.
    // Caching a positive result prevents those false negatives on later pastes.
    fileprivate var hasConfirmedEnabled = false
}

// MARK: - Permission
extension AccessibilityService {
    // Accessibility permission is required for simulating paste (Cmd+V) via CGEvent from macOS 10.14 Mojave.
    @discardableResult
    func isAccessibilityEnabled(isPrompt: Bool) -> Bool {
        guard #available(macOS 10.14, *) else { return true }

        // Trust was already confirmed earlier in this session; don't re-check,
        // since the checks below can fail transiently and re-trigger the alert.
        if hasConfirmedEnabled { return true }

        let checkOptionPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [checkOptionPromptKey: false] as CFDictionary
        if AXIsProcessTrustedWithOptions(opts) {
            hasConfirmedEnabled = true
            return true
        }
        // AXIsProcessTrustedWithOptions can return false for unsigned/ad-hoc signed
        // builds even when accessibility is granted. Verify with a practical test
        // before showing any prompt. The probe can also fail transiently (e.g. the
        // target app is momentarily busy right after the menu closes), so retry a
        // few times before concluding that trust is missing.
        if isAccessibilityGrantedByProbe() {
            hasConfirmedEnabled = true
            return true
        }
        if isPrompt {
            let promptOpts = [checkOptionPromptKey: true] as CFDictionary
            AXIsProcessTrustedWithOptions(promptOpts)
        }
        return false
    }

    private func isAccessibilityGrantedByProbe() -> Bool {
        for attempt in 0..<3 {
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                AXUIElementCreateSystemWide(),
                kAXFocusedApplicationAttribute as CFString,
                &value
            )
            // .success means an app has focus and we got it — trust is granted.
            // .noValue means no app has focus (e.g. menu just closed) but the API
            // accepted the call — trust is still granted.
            // .apiDisabled or .cannotComplete means no trust (or a transient failure).
            if result == .success || result == .noValue {
                return true
            }
            // Brief backoff before retrying a transient failure.
            if attempt < 2 {
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        return false
    }

    func showAccessibilityAuthenticationAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Please allow Accessibility")
        alert.informativeText = String(localized: "To do this action please allow Accessibility in Security Privacy preferences located in System Preferences")
        alert.addButton(withTitle: String(localized: "Open System Preferences"))
        NSApp.activate(ignoringOtherApps: true)

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            guard !openAccessibilitySettingWindow() else { return }
            isAccessibilityEnabled(isPrompt: true)
        }
    }

    func openAccessibilitySettingWindow() -> Bool {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return false }
        return NSWorkspace.shared.open(url)
    }
}
