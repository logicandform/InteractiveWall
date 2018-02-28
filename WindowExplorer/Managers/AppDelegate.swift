//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

struct Configuration {
    static let numberOfWindows = 2
    static let frameless = false
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
}

enum WindowNotifications: String {
    case place

    var name: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }

    static var allValues: [WindowNotifications] {
        return [.place]
    }
}

let deviceID = Int32(1)



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private struct Keys {
        static let position = "position"
        static let place = "place"
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for notification in WindowNotifications.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        switch notification.name {
        case WindowNotifications.place.name:
            handlePlace(notification)
        default:
            return
        }
    }


    // MARK: Helpers

    private func handlePlace(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo, let positionJSON = userInfo[Keys.position] as? [String: Any], var location = CGPoint(fromJSON: positionJSON), let place = userInfo[Keys.place] as? String else {
            return
        }

        let storyboard = NSStoryboard(name: PlaceViewController.storyboard, bundle: Bundle.main)
        let placeVC = storyboard.instantiateInitialController() as! PlaceViewController
        // get screen for the mapID displaying place
        let screen = NSScreen.screens[0]
        let size = PlaceViewController.size
        location -= CGVector(dx: size.width / 2, dy: size.height)
        let windowFrame = NSRect(x: location.x, y: location.y, width: size.width, height: size.height)
        let placeWindow = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        placeWindow.backgroundColor = NSColor.clear
        placeWindow.level = .statusBar
        placeWindow.contentViewController = placeVC
        placeWindow.setFrame(windowFrame, display: true)
        placeWindow.makeKeyAndOrderFront(self)
    }
}

