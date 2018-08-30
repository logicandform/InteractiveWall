//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "InfoMenu")

    @IBOutlet weak var infoScrollView: FadingScrollView!
    @IBOutlet weak var infoClipView: NSClipView!
    @IBOutlet weak var infoCollectionView: NSCollectionView!

    var gestureManager: GestureManager!
    private var infoEntries = [InfoMenuItem]()


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)

        setupInfoData()
        setupLayers()
        setupCollectionView()
        setupGestures()
    }


    // MARK: API

    func updateOrigin(relativeTo verticalPosition: CGFloat, with buttonFrame: CGRect) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        let translatedPosition = verticalPosition + buttonFrame.origin.y + buttonFrame.height - view.frame.height
        let updatedVerticalPosition = translatedPosition < 0 ? screen.frame.minY : translatedPosition
        view.window?.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: updatedVerticalPosition))
    }


    // MARK: GestureResponder

    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        return bounds.contains(view.frame.transformed(from: window.frame))
    }

    func subview(contains position: CGPoint) -> Bool {
        return view.isHidden ? false : view.frame.contains(position)
    }


    // MARK: NSCollectionViewDelegateFlowLayout and NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoEntries.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let infoView = infoCollectionView.makeItem(withIdentifier: InfoMenuItemView.identifier, for: indexPath) as? InfoMenuItemView else {
            return NSCollectionViewItem()
        }

        infoView.titleTextField.attributedStringValue = NSMutableAttributedString(string: infoEntries[indexPath.item].title, attributes: infoEntries[indexPath.item].titleAttributes)
        setup(textField: infoView.titleTextField)
        infoView.descriptionTextField.attributedStringValue = NSMutableAttributedString(string: infoEntries[indexPath.item].description, attributes: infoEntries[indexPath.item].descriptionAttributes)
        setup(textField: infoView.descriptionTextField)

        return infoView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: infoCollectionView.frame.size.width, height: InfoMenuItemView.infoItemHeight(for: infoEntries[indexPath.item]))
    }


    // MARK: Gesture Handling

    private func didPanOnTimeline(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = infoCollectionView.visibleRect
            rect.origin.y += pan.delta.dy
            infoCollectionView.scrollToVisible(rect)
            infoScrollView.updateGradient()
        default:
            return
        }
    }


    // MARK: Helpers

    private func setupInfoData() {
        guard let interactiveData = School(json: interactiveJSON), let interactiveDescription = interactiveData.description, let featuresData = School(json: featuresJSON), let featuresDescription = featuresData.description else {
            return
        }

        let interactiveEntry = InfoMenuItem(title: interactiveData.title, description: interactiveDescription, video: nil)
        let featuresEntry = InfoMenuItem(title: featuresData.title, description: featuresDescription, video: nil)
        infoEntries = [interactiveEntry, featuresEntry]
    }

    private func setupLayers() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        infoCollectionView.backgroundColors = [style.darkBackground]
    }

    private func setupCollectionView() {
        infoCollectionView.register(InfoMenuItemView.self, forItemWithIdentifier: InfoMenuItemView.identifier)
        infoScrollView.verticalScroller?.alphaValue = 0
        infoScrollView.updateGradient()
    }

    private func setupGestures() {
        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: infoCollectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }
    }

    private func setup(textField: NSTextField) {
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = false
        textField.sizeToFit()
        textField.cell?.wraps = true
    }
}
