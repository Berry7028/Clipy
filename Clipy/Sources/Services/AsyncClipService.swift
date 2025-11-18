//
//  AsyncClipService.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Claude on 2025/11/18.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa
import RealmSwift
import PINCache

@available(macOS 15.0, *)
@MainActor
final class AsyncClipService {

    // MARK: - Properties
    private var monitoringTask: Task<Void, Never>?
    private var lastChangeCount: Int = 0
    private var storeTypes = [String: NSNumber]()

    // MARK: - Monitoring

    func startMonitoring() async {
        // Cancel any existing task
        monitoringTask?.cancel()

        // Start new monitoring task
        monitoringTask = Task {
            await withTaskGroup(of: Void.self) { group in
                // Pasteboard monitoring
                group.addTask { [weak self] in
                    await self?.monitorPasteboard()
                }

                // Store types monitoring
                group.addTask { [weak self] in
                    await self?.monitorStoreTypes()
                }
            }
        }
    }

    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    // MARK: - Private Monitoring

    private func monitorPasteboard() async {
        while !Task.isCancelled {
            let currentCount = NSPasteboard.general.changeCount

            if currentCount != lastChangeCount {
                lastChangeCount = currentCount
                await createClip()
            }

            // Check every 750ms
            try? await Task.sleep(nanoseconds: 750_000_000)
        }
    }

    private func monitorStoreTypes() async {
        // Initial load
        if let types = AppEnvironment.current.defaults.dictionary(forKey: Constants.UserDefaults.storeTypes) as? [String: NSNumber] {
            storeTypes = types
        }

        // Monitor changes
        for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
            if Task.isCancelled { break }

            if let types = AppEnvironment.current.defaults.dictionary(forKey: Constants.UserDefaults.storeTypes) as? [String: NSNumber] {
                storeTypes = types
            }
        }
    }

    // MARK: - Clip Management

    func createClip() async {
        // Check if should store
        guard storeTypes.values.contains(NSNumber(value: true)) else { return }

        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types, !types.isEmpty else { return }

        // Check excluded apps
        guard !AppEnvironment.current.excludeAppService.frontProcessIsExcludedApplication() else { return }
        guard !AppEnvironment.current.excludeAppService.copiedProcessIsExcludedApplications(pasteboard: pasteboard) else { return }

        // Create clip data
        await Task.detached(priority: .userInitiated) {
            await MainActor.run {
                // Use existing ClipService logic
                AppEnvironment.current.clipService.create()
            }
        }.value
    }

    func clearAll() async {
        await Task.detached(priority: .userInitiated) {
            let realm = try! Realm()
            let clips = realm.objects(CPYClip.self)

            // Delete saved images
            await withTaskGroup(of: Void.self) { group in
                for clip in clips where !clip.thumbnailPath.isEmpty {
                    group.addTask {
                        PINCache.shared.removeObject(forKey: clip.thumbnailPath)
                    }
                }
            }

            // Delete Realm data
            try? realm.write {
                realm.delete(clips)
            }

            // Clean data files
            await MainActor.run {
                AppEnvironment.current.dataCleanService.cleanDatas()
            }
        }.value
    }

    func delete(clip: CPYClip) async {
        await Task.detached(priority: .userInitiated) {
            let realm = try! Realm()

            // Delete image if exists
            let path = clip.thumbnailPath
            if !path.isEmpty {
                PINCache.shared.removeObject(forKey: path)
            }

            // Delete from Realm
            try? realm.write {
                realm.delete(clip)
            }
        }.value
    }

    func fetchClips(limit: Int? = nil, filter: String? = nil) async -> [CPYClip] {
        await Task.detached(priority: .userInitiated) {
            let realm = try! Realm()
            var results = realm.objects(CPYClip.self)
                .sorted(byKeyPath: #keyPath(CPYClip.updateTime), ascending: false)

            if let filter = filter, !filter.isEmpty {
                results = results.filter("title CONTAINS[cd] %@", filter)
            }

            if let limit = limit {
                return Array(results.prefix(limit))
            } else {
                return Array(results)
            }
        }.value
    }

    func toggleFavorite(clip: CPYClip) async {
        await Task.detached(priority: .userInitiated) {
            let realm = try! Realm()
            guard let clip = realm.object(ofType: CPYClip.self, forPrimaryKey: clip.dataHash) else { return }

            try? realm.write {
                clip.isFavorite.toggle()
                if clip.isFavorite {
                    let maxIndex = realm.objects(CPYClip.self)
                        .filter("isFavorite == true")
                        .max(ofProperty: "favoriteIndex") as Int? ?? -1
                    clip.favoriteIndex = maxIndex + 1
                }
            }
        }.value
    }

    func getFavorites() async -> [CPYClip] {
        await Task.detached(priority: .userInitiated) {
            let realm = try! Realm()
            return Array(realm.objects(CPYClip.self)
                .filter("isFavorite == true")
                .sorted(byKeyPath: #keyPath(CPYClip.favoriteIndex), ascending: true))
        }.value
    }
}

// MARK: - NotificationCenter Async Extension

@available(macOS 15.0, *)
extension NotificationCenter {
    func notifications(named name: Notification.Name,
                      object: AnyObject? = nil) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(forName: name, object: object, queue: nil) { notification in
                continuation.yield(notification)
            }

            continuation.onTermination = { @Sendable _ in
                self.removeObserver(observer)
            }
        }
    }
}
