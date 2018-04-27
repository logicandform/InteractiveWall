//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit


class RecordTypeSelectionView: NSView {

    var selectionCallback: ((RecordType?) -> Void)?

    @IBOutlet weak var stackview: NSStackView! {
        didSet {
            stackview.wantsLayer = true
            stackview.layer?.backgroundColor = style.darkBackground.cgColor
            stackview.edgeInsets = Constants.stackviewEdgeInsets
        }
    }

    private var selectedView: NSView? {
        didSet {
            unselect(oldValue)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
        static let imageHeight: CGFloat = 24
        static let stackviewEdgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }


    // MARK: API

    func initialize(with record: RecordDisplayable, manager: GestureManager) {
        // Only display views if the record has related items of that type
        let relatedTypesForRecord = record.recordGroups.filter { !$0.records.isEmpty }.map { $0.type }

        relatedTypesForRecord.forEach { type in
            let view = NSView()
            view.wantsLayer = true
            view.layer?.contents = type.placeholder.tinted(with: style.unselectedRecordIcon)
            stackview.addView(view, in: .leading)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            addGesture(to: view, in: manager, for: type)
        }
    }


    // MARK: Helpers

    private func addGesture(to view: NSView, in manager: GestureManager, for type: RecordType) {
        let tapGesture = TapGestureRecognizer()
        manager.add(tapGesture, to: view)

        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didTap(view, for: type)
            }
        }
    }

    private func didTap(_ view: NSView, for type: RecordType) {
        if view == selectedView {
            selectedView = nil
            selectionCallback?(nil)
        } else {
            view.transition(to: type.placeholder.tinted(with: type.color), duration: Constants.imageTransitionDuration)
            selectedView = view
            selectionCallback?(type)
        }
    }

    private func unselect(_ view: NSView?) {
        guard let view = view, let image = view.layer?.contents as? NSImage else {
            return
        }

        view.transition(to: image.tinted(with: style.unselectedRecordIcon), duration: Constants.imageTransitionDuration)
    }
}
