//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit

let style = Style()


struct Configuration {
    static let mapsPerScreen = 1
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let loadMapsOnFirstScreen = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        RecordFactory.record(for: .artifact, id: 2279) { artifact in
            if let artifact = artifact {
                WindowManager.instance.display(.record(artifact), at: CGPoint(x: 1500, y: 1000))
            }
        }

        RecordFactory.record(for: .artifact, id: 2278) { artifact in
            if let artifact = artifact {
                WindowManager.instance.display(.record(artifact), at: CGPoint(x: 2000, y: 1000))
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

