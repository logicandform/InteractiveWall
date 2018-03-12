//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum WindowType {
    case record(RecordDisplayable)
    case place
    case player
    case pdf

    var size: CGSize {
        switch self {
        case .record:
            return CGSize(width: 416, height: 600)
        default:
            return CGSize(width: 640, height: 600)
        }
    }
}


final class WindowFactory {


    // MARK: API

    static func window(for type: WindowType, at origin: CGPoint) -> NSWindow {
        let frame = CGRect(origin: origin, size: type.size)
        let viewController = controller(for: type)
        viewController.view.setFrameSize(frame.size)
        let window = BorderlessWindow(frame: frame, controller: viewController)
        window.makeKeyAndOrderFront(self)
        return window
    }


    // MARK: Helpers

    private static func controller(for type: WindowType) -> NSViewController {
        switch type {
        case .record(let displayable):
            let storyboard = NSStoryboard(name: RecordViewController.storyboard, bundle: Bundle.main)
            let recordViewController = storyboard.instantiateInitialController() as! RecordViewController
            recordViewController.record = displayable
            return recordViewController
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
