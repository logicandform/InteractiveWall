//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class MenuManager {
    static let instance = MenuManager()

    // MenuViewControllers indexed by their associated appID
    private var menuForID = [Int: MenuViewController]()

    // BorderViewControllers indexed by their associated appID
    private var borderForApp = [Int: BorderViewController]()


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    func createMenusAndBorders() {
        for screen in (1 ... Configuration.numberOfScreens) {
            let screenFrame = NSScreen.at(position: screen).frame

            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let appID = appIndex + ((screen - 1) * Configuration.appsPerScreen)

                // Setup Menus
                let menuX = appIndex.isEven ? screenFrame.minX : screenFrame.maxX - style.menuWindowSize.width
                let menuY = screenFrame.midY - screenFrame.height / 2
                if let menu = WindowManager.instance.display(.menu(app: appID), at: CGPoint(x: menuX, y: menuY)) as? MenuViewController {
                    menuForID[appID] = menu
                }

                // Setup Borders
                let borderX = appIndex.isEven ? screenFrame.midX - style.borderWindowSize.width / 2 : screenFrame.maxX - style.borderWindowSize.width / 2
                let maxID = Configuration.numberOfScreens * Configuration.appsPerScreen - 1
                if appID < maxID {
                    let border = WindowManager.instance.display(.border, at: CGPoint(x: borderX, y: 0)) as? BorderViewController
                    borderForApp[appID] = border
                }
            }
        }
    }

    func menuForApp(id: Int) -> MenuViewController? {
        return menuForID[id]
    }

    func borderForApp(id: Int) -> BorderViewController? {
        return borderForApp[id]
    }
}
