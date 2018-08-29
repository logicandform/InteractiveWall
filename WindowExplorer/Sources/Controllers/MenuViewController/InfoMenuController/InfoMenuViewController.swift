//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class InfoMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "InfoMenu")

    @IBOutlet weak var stackScrollView: FadingScrollView!
    @IBOutlet weak var stackClipView: NSClipView!
    @IBOutlet weak var stackView: NSStackView!

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
        stackView.wantsLayer = true
        stackClipView.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        stackView.layer?.backgroundColor = style.darkBackground.cgColor
        stackClipView.layer?.backgroundColor = style.darkBackground.cgColor
    }
}
