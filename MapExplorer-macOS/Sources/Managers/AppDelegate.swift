//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let mapsPerScreen = 2
    static let numberOfScreens = 3
    static let touchScreenSize = CGSize(width: 4095, height: 4095)
    static let refreshRate: Double = 1 / 60
}


var screenID = 0
var appID = 0


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let screenIndex = Int(CommandLine.arguments[1]) ?? 0
        let appIndex = Int(CommandLine.arguments[2]) ?? 0

        let screen = NSScreen.at(position: screenIndex)
        screenID = screenIndex
        appID = appIndex + ((screenIndex - 1) * Configuration.mapsPerScreen)

        let mapStoryboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)
        let mapController = mapStoryboard.instantiateInitialController() as! MapViewController
        let mapWindow: NSWindow
        let screenWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let frame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(appIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
        mapWindow = BorderlessWindow(frame: frame, controller: mapController)
        mapWindow.setFrame(frame, display: true)
        mapWindow.makeKeyAndOrderFront(self)

        /// Display the DemoViewController
//        let demoStoryboard = NSStoryboard(name: GestureDemoController.storyboard, bundle: nil)
//        let demoVC = demoStoryboard.instantiateIni5tialController() as! GestureDemoController
//        let demoWindow = NSWindow(contentViewController: demoVC)
//        demoWindow.title = "Demo Window"Ø
//        demoWindow.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
