//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


struct Configuration {
    static let serverIP = "10.58.73.102"
    static let serverURL = "http://\(serverIP):3000"
    static let mapsPerScreen = 2
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
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

        let controller = MapViewController.instance()
        let screenWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let frame = NSRect(x: screen.frame.minX + screenWidth * CGFloat(appIndex), y: screen.frame.minY, width: screenWidth, height: screen.frame.height)
        let window = BorderlessWindow(frame: frame, controller: controller)
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(self)

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
