//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum WindowType {
    case place
    case player
    case pdf

    var size: CGSize {
        return CGSize(width: 640, height: 600)
    }
}


final class WindowFactory {


    // MARK: API

    static func window(for type: WindowType, at origin: CGPoint) -> NSWindow {
        let frame = CGRect(origin: origin, size: type.size)
        let window = BorderlessWindow(frame: frame, controller: controller(for: type))
        window.makeKeyAndOrderFront(self)
        return window
    }


    // MARK: Helpers

    private static func controller(for type: WindowType) -> NSViewController {
        switch type {
        case .place:
            let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: Bundle.main)
            return storyboard.instantiateInitialController() as! PlaceViewController
        case .player:
            let storyboard = NSStoryboard(name: PlayerViewController.storyboard, bundle: Bundle.main)
            return storyboard.instantiateInitialController() as! PlayerViewController
        case .pdf:
            let storyboard = NSStoryboard(name: PDFViewController.storyboard, bundle: Bundle.main)
            return storyboard.instantiateInitialController() as! PDFViewController
        }
    }
}
