//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit

let style = Style()

struct Configuration {
    static let mapsPerScreen = 1
    static let touchScreenSize = CGSize(width: 4095, height: 2242.5)
    static let touchScreenRatio: CGFloat = 23.0 / 42.0
    static let loadMapsOnFirstScreen = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        RecordFactory.record(for: .artifact, id: 1599) { record in
            if let record = record {
                WindowManager.instance.display(.record(record), at: CGPoint(x: 3000, y: 200))
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

