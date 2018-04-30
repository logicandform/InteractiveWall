//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit


class RecordTypeSelectionView: NSView {

    @IBOutlet weak var stackview: NSStackView! {
        didSet {
            stackview.wantsLayer = true
            stackview.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    var selectionCallback: ((RecordType?) -> Void)?
    private var imageForType = [RecordType: NSView]()
    private var selectedType: RecordType? {
        didSet {
            selectionCallback?(selectedType)
            unselect(oldValue)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
        static let imageHeight: CGFloat = 24
    }


    // MARK: API

    func initialize(with record: RecordDisplayable, manager: GestureManager) {
        // Only display views if the record has related items of that type
        let relatedTypesForRecord = record.recordGroups.filter { !$0.records.isEmpty }.map { $0.type }

        relatedTypesForRecord.forEach { type in
            // Use two views to increase hit area of image while image is centered
            let view = NSView()
            let image = NSView()
            view.addSubview(image)
            image.wantsLayer = true
            image.layer?.contents = type.placeholder.tinted(with: style.unselectedRecordIcon)
            stackview.addView(view, in: .leading)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.heightAnchor.constraint(equalTo: stackview.heightAnchor).isActive = true
            view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            image.translatesAutoresizingMaskIntoConstraints = false
            image.widthAnchor.constraint(equalToConstant: Constants.imageHeight).isActive = true
            image.heightAnchor.constraint(equalToConstant: Constants.imageHeight).isActive = true
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            image.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            imageForType[type] = image
            addGesture(to: view, in: manager, for: type)
        }
    }


    // MARK: Helpers

    private func addGesture(to view: NSView, in manager: GestureManager, for type: RecordType) {
        let tapGesture = TapGestureRecognizer()
        manager.add(tapGesture, to: view)

        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didSelect(type: type)
            }
        }
    }

    private func didSelect(type: RecordType) {
        if type == selectedType {
            selectedType = nil
        } else if let image = imageForType[type] {
            selectedType = type
            image.transition(to: type.placeholder.tinted(with: type.color), duration: Constants.imageTransitionDuration)
        }
    }

    private func unselect(_ type: RecordType?) {
        guard let type = type, let image = imageForType[type], let currentImage = image.layer?.contents as? NSImage else {
            return
        }

        image.transition(to: currentImage.tinted(with: style.unselectedRecordIcon), duration: Constants.imageTransitionDuration)
    }
}
