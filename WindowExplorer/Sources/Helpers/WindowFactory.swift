//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum WindowType {
    case place
    case player
    case pdf
}


final class WindowFactory {

    private struct Constants {
        static let windowSize = CGSize(width: 640, height: 600)
    }


    // MARK: API

    static func window(for type: WindowType, screen: Int, at topMiddle: CGPoint) -> NSWindow? {
        guard let screen = NSScreen.screens.at(index: screen), let window = window(in: screen, at: topMiddle) else {
            return nil
        }
        
        window.contentViewController = controller(for: type)
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

    private static func window(in screen: NSScreen, at topMiddle: CGPoint) -> NSWindow? {
        let origin = screen.frame.origin + topMiddle - CGPoint(x: Constants.windowSize.width / 2, y: Constants.windowSize.height)
        let windowFrame = NSRect(origin: origin, size: Constants.windowSize)
        let window = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        window.level = .statusBar
        window.setFrame(windowFrame, display: true)
        window.backgroundColor = NSColor.clear
        window.makeKeyAndOrderFront(self)
        return window
    }
}
