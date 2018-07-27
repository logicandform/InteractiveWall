//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13000
    static let serverIP = "10.58.73.211"
    static let broadcastIP = "10.58.73.255"
    static let serverURL = "http://\(serverIP):3000"
    static let appsPerScreen = 2
    static let numberOfScreens = 3
    static let localMediaURLs = true
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate = 1.0 / 60.0
}


struct Paths {
    static let mapExplorer = "/Users/irshdc/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/MapExplorer-macOS.app"
//    static let mapExplorer = "/Users/juneha/Library/Developer/Xcode/DerivedData/MapExplorer-egvtpmlvcohzalbqgbyfrerzbcdi/Build/Products/Debug/MapExplorer-macOS.app"
//    static let mapExplorer = "/Users/Tim/Library/Developer/Xcode/DerivedData/MapExplorer-btnxiobgycwlwddqfdkwxqhmpeum/Build/Products/Debug/MapExplorer-macOS.app"
//    static let mapExplorer = "/Users/harrisonturley/Library/Developer/Xcode/DerivedData/MapExplorer-advgqestfqggadbethjhtmretrda/Build/Products/Debug/MapExplorer-macOS.app"
//    static let mapExplorer = "/Users/spencerperkins/Library/Developer/Xcode/DerivedData/MapExplorer-cfmuxpkdowxydndtaoqzbobzopot/Build/Products/Debug/MapExplorer-macOS.app"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        ConnectionManager.instance.registerForNotifications()
        SettingsManager.instance.registerForNotifications()
        SelectionManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        MenuManager.instance.createMenusAndBorders()
        GeocodeHelper.instance.associateSchoolsToProvinces()
        MasterViewController.instantiate()
    }
}
