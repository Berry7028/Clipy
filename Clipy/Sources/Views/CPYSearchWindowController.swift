//
//  CPYSearchWindowController.swift
//
//  Clipy
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Claude on 2025/11/18.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import RealmSwift
import RxSwift
import RxCocoa

@MainActor
final class CPYSearchWindowController: NSWindowController {

    // MARK: - Properties
    static let shared = CPYSearchWindowController()

    private let searchField = NSSearchField()
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let disposeBag = DisposeBag()
    private let realm = try! Realm()

    private var filteredClips: Results<CPYClip>?
    private var allClips: Results<CPYClip>

    // MARK: - Initialize
    private init() {
        allClips = realm.objects(CPYClip.self).sorted(byKeyPath: #keyPath(CPYClip.updateTime), ascending: false)
        filteredClips = allClips

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Search Clipboard History"
        window.level = .floating
        window.center()

        super.init(window: window)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        guard let window = window, let contentView = window.contentView else { return }

        // Search field
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search clipboard history..."
        contentView.addSubview(searchField)

        // Table view
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ClipColumn"))
        column.title = "Clipboard Items"
        column.width = 580
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        contentView.addSubview(scrollView)

        // Layout
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func bind() {
        searchField.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] query in
                self?.filterClips(query)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    private func filterClips(_ query: String) {
        if query.isEmpty {
            filteredClips = allClips
        } else {
            filteredClips = allClips.filter("title CONTAINS[cd] %@", query)
        }
        tableView.reloadData()
    }

    @objc private func tableViewDoubleClick() {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0, let clips = filteredClips, selectedRow < clips.count else { return }

        let clip = clips[selectedRow]
        AppEnvironment.current.pasteService.paste(with: clip)
        window?.close()
    }

    // MARK: - Public Methods
    func show() {
        searchField.stringValue = ""
        filteredClips = allClips
        tableView.reloadData()
        showWindow(self)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        searchField.becomeFirstResponder()
    }
}

// MARK: - NSTableViewDataSource
extension CPYSearchWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredClips?.count ?? 0
    }
}

// MARK: - NSTableViewDelegate
extension CPYSearchWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let clips = filteredClips, row < clips.count else { return nil }

        let clip = clips[row]
        let cellView = NSTableCellView()

        let textField = NSTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.stringValue = clip.title
        textField.lineBreakMode = .byTruncatingTail

        cellView.addSubview(textField)
        cellView.textField = textField

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 5),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -5),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])

        return cellView
    }
}
