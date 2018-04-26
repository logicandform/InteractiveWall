//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class WindowFactory {


    // MARK: API

    static func window(for type: WindowType, at origin: CGPoint) -> NSWindow {
        let viewController = controller(for: type)
        viewController.view.setFrameSize(type.size)
        let window = BorderlessWindow(frame: CGRect(origin: origin, size: type.size), controller: viewController)
        window.makeKeyAndOrderFront(self)
        return window
    }


    // MARK: Helpers

    private static func controller(for type: WindowType) -> NSViewController {
        switch type {
        case let .record(displayable):
            let storyboard = NSStoryboard(name: RecordViewController.storyboard, bundle: .main)
            let recordViewController = storyboard.instantiateInitialController() as! RecordViewController
            recordViewController.record = displayable
            return recordViewController
        case let .image(media):
            let storyboard = NSStoryboard(name: ImageViewController.storyboard, bundle: .main)
            let imageViewController = storyboard.instantiateInitialController() as! ImageViewController
            imageViewController.media = media
            return imageViewController
        case let .player(media):
            let storyboard = NSStoryboard(name: PlayerViewController.storyboard, bundle: .main)
            let playerViewController = storyboard.instantiateInitialController() as! PlayerViewController
            playerViewController.media = media
            return playerViewController
        case let .pdf(media):
            let storyboard = NSStoryboard(name: PDFViewController.storyboard, bundle: .main)
            let pdfViewController = storyboard.instantiateInitialController() as! PDFViewController
            pdfViewController.media = media
            return pdfViewController
        }
    }
}
