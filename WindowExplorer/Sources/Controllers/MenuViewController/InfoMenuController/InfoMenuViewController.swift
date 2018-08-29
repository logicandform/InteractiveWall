//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "InfoMenu")

    @IBOutlet weak var infoScrollView: NSScrollView!
    @IBOutlet weak var infoClipView: NSClipView!
    @IBOutlet weak var infoCollectionView: NSCollectionView!

    var gestureManager: GestureManager!


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)

        setupInfoData()
        setupLayers()
        setupCollectionView()
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
        return true
    }


    // MARK: NSCollectionViewDelegateFlowLayout and NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: infoCollectionView.frame.size.width, height: 50)
    }


    // MARK: Helpers

    private func setupInfoData() {
        guard let textFields = School(json: featuresJSON)?.textFields else {
            return
        }

        
    }

    private func setupLayers() {
        view.wantsLayer = true
        infoScrollView.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        infoScrollView.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func setupCollectionView() {
        infoScrollView.verticalScroller?.alphaValue = 0
    }
}
