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
                let menuX = appIndex.isEven ? screenFrame.minX : screenFrame.maxX - style.menuWindowWidth
                let menuY = screenFrame.midY - screenFrame.height / 2
                if let menu = WindowManager.instance.display(.menu(app: appID), at: CGPoint(x: menuX, y: menuY)) as? MenuViewController {
                    menuForID[appID] = menu
                }

                // Setup Borders
                let borderWidth = appIndex.isEven ? style.borderWindowWidth : style.borderWindowWidth * 2
                let borderX = appIndex.isEven ? screenFrame.midX - borderWidth / 2 : screenFrame.maxX - borderWidth / 2
                let maxID = Configuration.numberOfScreens * Configuration.appsPerScreen - 1
                if appID < maxID {
                    let border = WindowManager.instance.display(.border(app: appID), at: CGPoint(x: borderX, y: 0)) as? BorderViewController
                    borderForApp[appID] = border
                }
            }
        }
    }

    /// Called after a screen gets dissconnected and reconnected to fix window positioning
    func updateMenuAndBorderPositions() {
        for (id, menu) in menuForID {
            let screenID = screen(of: id)
            let screenFrame = NSScreen.at(position: screenID).frame
            let x = id.isEven ? screenFrame.minX : screenFrame.maxX - style.menuWindowWidth
            let y = screenFrame.midY - screenFrame.height / 2

            menu.view.window?.setFrameOrigin(CGPoint(x: x, y: y))
        }

        for (id, border) in borderForApp {
            let screenID = screen(of: id)
            let screenFrame = NSScreen.at(position: screenID).frame
            let borderWidth = id.isEven ? style.borderWindowWidth : style.borderWindowWidth * 2
            let x = id.isEven ? screenFrame.midX - borderWidth / 2 : screenFrame.maxX - borderWidth / 2

            border.view.window?.setFrameOrigin(CGPoint(x: x, y: 0))
        }
    }

    func menuForApp(id: Int) -> MenuViewController? {
        return menuForID[id]
    }

    func borderForApp(id: Int) -> BorderViewController? {
        return borderForApp[id]
    }


    // MARK: Helpers

    /// Returns the screen id of the given app id
    private func screen(of id: Int) -> Int {
        return (id / Configuration.appsPerScreen) + 1
    }
}
