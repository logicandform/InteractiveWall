//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MacGestures


protocol RecordFilterDelegate: class {
    func canSelectFilterType(_ type: RecordFilterType) -> Bool
    func didSelectFilterType(_ type: RecordFilterType)
}


class RecordTypeSelectionView: NSView {

    @IBOutlet weak var stackview: NSStackView!

    weak var delegate: RecordFilterDelegate?
    private var imageForType = [RecordFilterType: NSView]()
    private var selectedType: RecordFilterType = .all {
        didSet {
            unselect(oldValue)
            delegate?.didSelectFilterType(selectedType)
        }
    }

    private struct Constants {
        static let imageTransitionDuration = 0.5
        static let imageHeight: CGFloat = 24
        static let maxFilterTypesPerRecord = 6
    }


    // MARK: API

    func initialize(with record: Record, manager: GestureManager) {
        let availableTypes = RecordFilterType.recordFilterValues.filter { !record.relatedRecords(filterType: $0).isEmpty }
        let filterTypesForRecord = availableTypes.prefix(Constants.maxFilterTypesPerRecord)

        filterTypesForRecord.forEach { type in
            // Use two views to increase hit area of image while image is centered
            let view = NSView()
            let image = NSView()
            view.addSubview(image)
            image.wantsLayer = true
            image.layer?.contents = type.placeholder?.tinted(with: style.unselectedRecordIcon)
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

    private func addGesture(to view: NSView, in manager: GestureManager, for type: RecordFilterType) {
        let tapGesture = TapGestureRecognizer()
        manager.add(tapGesture, to: view)

        tapGesture.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.didSelect(type: type)
            }
        }
    }

    private func didSelect(type: RecordFilterType) {
        guard let delegate = delegate, delegate.canSelectFilterType(type) else {
            return
        }

        if type == selectedType {
            selectedType = .all
        } else if let image = imageForType[type] {
            selectedType = type
            image.transition(to: type.placeholder?.tinted(with: type.color), duration: Constants.imageTransitionDuration)
        }
    }

    private func unselect(_ type: RecordFilterType?) {
        guard let type = type, let image = imageForType[type], let currentImage = image.layer?.contents as? NSImage else {
            return
        }

        image.transition(to: currentImage.tinted(with: style.unselectedRecordIcon), duration: Constants.imageTransitionDuration)
    }
}
