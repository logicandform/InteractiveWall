//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class MenuManager {
    static let instance = MenuManager()

    // MenuViewControllers indexed by their associated appID
    private var menuForID = [Int: MenuViewController]()


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    func createMenus() {
        for screen in (1 ... Configuration.numberOfScreens) {
            let screenFrame = NSScreen.at(position: screen).frame

            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let x = appIndex % 2 == 0 ? screenFrame.minX : screenFrame.maxX - style.menuWindowSize.width
                let y = screenFrame.midY - style.menuWindowSize.height / 2

                if let menu = WindowManager.instance.display(.menu, at: CGPoint(x: x, y: y)) as? MenuViewController {
                    let appID = appIndex + ((screen - 1) * Configuration.appsPerScreen)
                    menu.set(appID: appID)
                    menuForID[appID] = menu
                }
            }
        }
    }

    func menuForApp(id: Int) -> MenuViewController? {
        return menuForID[id]
    }
}
