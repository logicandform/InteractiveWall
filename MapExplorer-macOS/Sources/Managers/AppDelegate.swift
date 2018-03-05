//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let numberOfWindows = 4
    static let frameless = true
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
    static let touchScreenRatio: CGFloat = 23.0 / 42.0
}


var screenID = 0
var appID = 0


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screenIndex = Int(CommandLine.arguments[1]) ?? 0
        let windowIndex = Int(CommandLine.arguments[2]) ?? 0
        screenID = screenIndex
        appID = windowIndex + (screenID - 1) * Configuration.numberOfWindows

        let mapStoryboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)
        let mapVC = mapStoryboard.instantiateInitialController() as! MapViewController
        let mapWindow: NSWindow

        if Configuration.frameless {
            let screen = NSScreen.screens[screenIndex]
            let screenWidth = screen.frame.width / CGFloat(Configuration.numberOfWindows)
            let windowFrame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(windowIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
            mapWindow = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
            mapWindow.level = .statusBar
            mapWindow.contentViewController = mapVC
            mapWindow.setFrame(windowFrame, display: true)
        } else {
            mapWindow = NSWindow(contentViewController: mapVC)
        }

        mapWindow.title = "Map Window"
        mapWindow.makeKeyAndOrderFront(self)

        /// Display the DemoViewController
//        let demoStoryboard = NSStoryboard(name: GestureDemoController.storyboard, bundle: nil)
//        let demoVC = demoStoryboard.instantiateInitialController() as! GestureDemoController
//        let demoWindow = NSWindow(contentViewController: demoVC)
//        demoWindow.title = "Demo Window"
//        demoWindow.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
