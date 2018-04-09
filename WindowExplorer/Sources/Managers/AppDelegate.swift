//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit

let style = Style()


struct Configuration {
    static let mapsPerScreen = 3
    static let numberOfScreens = 3
    static let touchScreenSize = CGSize(width: 21564, height: 12116)
    static let refreshRate: Double = 1 / 60
    static let loadMapsOnFirstScreen = false
}


struct ShellCommands {
    static let openLaunchPath = "/usr/bin/open"
    static let openMapsBaseArg = ["-n", "-a", "/Users/\(NSUserName())/Library/Developer/Xcode/DerivedData/MapExplorer-cebdevedrroybgdstwjueirgqasq/Build/Products/Debug/MapExplorer-macOS.app", "--args"]
    static let killallLaunchPath = "/usr/bin/killall"
    static let killallArgs = ["MapExplorer-macOS"]
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        WindowManager.instance.registerForNotifications()
        TouchManager.instance.setupTouchSocket()
        launchMapExplorer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        killSubProcesses()
    }


    // MARK: Helpers

    private func launchMapExplorer() {
        for screen in 1 ... Configuration.numberOfScreens {
            for map in 0 ..< Configuration.mapsPerScreen {
                let args = ShellCommands.openMapsBaseArg + [String(screen), String(map)]
                shell(ShellCommands.openLaunchPath, args)
            }
        }
    }

    private func killSubProcesses() {
        shell(ShellCommands.killallLaunchPath, ShellCommands.killallArgs)
    }

    private func shell(_ launchPath: String, _ args: [String])  {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = args
        task.launch()
        task.waitUntilExit()
    }
}

