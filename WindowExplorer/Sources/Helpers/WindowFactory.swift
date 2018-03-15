//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


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
        case let .record(displayable):
            let storyboard = NSStoryboard(name: RecordViewController.storyboard, bundle: Bundle.main)
            let recordViewController = storyboard.instantiateInitialController() as! RecordViewController
            recordViewController.record = displayable
            return recordViewController
        case let .image(url):
            let storyboard = NSStoryboard(name: ImageViewController.storyboard, bundle: Bundle.main)
            let imageViewController = storyboard.instantiateInitialController() as! ImageViewController
            imageViewController.imageURL = url
            return imageViewController
        case let .player(url):
            let storyboard = NSStoryboard(name: PlayerViewController.storyboard, bundle: Bundle.main)
            let playerViewController = storyboard.instantiateInitialController() as! PlayerViewController
            playerViewController.videoURL = url
            return playerViewController
        case let .pdf(url):
            let storyboard = NSStoryboard(name: PDFViewController.storyboard, bundle: Bundle.main)
            let pdfViewController = storyboard.instantiateInitialController() as! PDFViewController
            pdfViewController.pdfURL = url
            return pdfViewController
        }
    }
}
