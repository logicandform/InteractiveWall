//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "InfoMenu")

    @IBOutlet weak var infoMenuScrollView: NSScrollView!
    @IBOutlet weak var infoMenuCollectionView: NSCollectionView!
    @IBOutlet weak var infoMenuClipView: NSClipView!

    var gestureManager: GestureManager!


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        setupLayers()
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


    // MARK: Helpers

    private func setupLayers() {
        view.wantsLayer = true
        infoMenuScrollView.wantsLayer = true
        infoMenuClipView.wantsLayer = true
        infoMenuCollectionView.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        infoMenuScrollView.layer?.backgroundColor = style.darkBackground.cgColor
        infoMenuClipView.layer?.backgroundColor = style.darkBackground.cgColor
        infoMenuCollectionView.layer?.backgroundColor = style.darkBackground.cgColor
    }
}
