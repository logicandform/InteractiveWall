//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

struct Configuration {
    static let numberOfWindows = 2
    static let numberOfMapsPerWindow = 1
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let mapManager = LocalMapManager()
        let mapStoryboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)

        let screenIndex = Int(CommandLine.arguments[1])!
        let windowIndex = Int(CommandLine.arguments[2])!
        let mapVC = mapStoryboard.instantiateInitialController() as! MapViewController
        let screen = NSScreen.screens[screenIndex]
        let screenFrame = screen.frame
        let screenWidth = screenFrame.width / CGFloat(Configuration.numberOfWindows)
        let windowFrame = NSRect(x: screenWidth * CGFloat(windowIndex), y: 0, width: screenWidth, height: screenFrame.height)
        let mapWindow = NSWindow(contentRect: windowFrame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        mapWindow.contentViewController = mapVC
        mapWindow.setFrame(windowFrame, display: true)
        mapWindow.level = .statusBar
        mapWindow.title = "Map Window \(index)"
        mapWindow.makeKeyAndOrderFront(self)
        mapManager.add(mapVC.mapViews)
        mapVC.mapManager = mapManager

        mapManager.reset()

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
