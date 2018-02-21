//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private struct Configuration {
        static let numberOfWindows = 1
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let sharedActivityController = LocalMapActivityController()
        let mapStoryboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)

        for index in (1 ... Configuration.numberOfWindows) {
            let mapVC = mapStoryboard.instantiateInitialController() as! MapViewController
            let mapWindow = NSWindow(contentViewController: mapVC)
            mapWindow.title = "Map Window \(index)"
            mapWindow.makeKeyAndOrderFront(self)
            sharedActivityController.add(mapVC.mapViews)
            mapVC.activityController = sharedActivityController
        }

        /// Display the DemoViewController
//        let demoStoryboard = NSStoryboard(name: GestureDemoController.storyboard, bundle: nil)
//        let demoVC = mapStoryboard.instantiateInitialController() as! GestureDemoController
//        let demoWindow = NSWindow(contentViewController: demoVC)
//        demoWindow.title = "Demo Window"
//        demoWindow.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
