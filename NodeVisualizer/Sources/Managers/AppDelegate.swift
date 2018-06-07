//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let mapsPerScreen = 2
    static let numberOfScreens = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
    static let loadMapsOnFirstScreen = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        let vc = MainViewController.instance()
        let screen = NSScreen.main!
        let window = NSWindow()
        let origin = CGPoint(x: screen.frame.midX - vc.view.frame.width / 2, y: screen.frame.midY - vc.view.frame.height / 2)
        window.contentViewController = vc
        window.title = "Node Visualizer"
        window.setFrame(CGRect(origin: origin, size: vc.view.frame.size), display: true)
        window.styleMask.insert(.resizable)
        window.makeKeyAndOrderFront(self)

    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}
