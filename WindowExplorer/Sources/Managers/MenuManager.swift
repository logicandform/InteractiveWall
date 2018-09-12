//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class MenuManager {
    static let instance = MenuManager()

    // MenuViewControllers indexed by their associated appID
    private var menuForID = [Int: MenuViewController]()

    // BorderViewControllers indexed by their associated screenID
    private var borderForScreen = [Int: BorderViewController]()


    // MARK: Init

    /// Use singleton
    private init() {}


    // MARK: API

    func createMenusAndBorders() {
        for screen in (1 ... Configuration.numberOfScreens) {
            let screenFrame = NSScreen.at(position: screen).frame

            for appIndex in (0 ..< Configuration.appsPerScreen) {
                let x = appIndex.isEven ? screenFrame.minX : screenFrame.maxX - style.menuWindowSize.width
                let y = screenFrame.midY - style.menuWindowSize.height / 2
                let borderXPosition = (screenFrame.size.width / 2) + screenFrame.origin.x - (style.borderWindowSize.width / 2)
                let appID = appIndex + ((screen - 1) * Configuration.appsPerScreen)

                if let menu = WindowManager.instance.display(.menu(app: appID), at: CGPoint(x: x, y: y)) as? MenuViewController {
                    menuForID[appID] = menu
                }

                if !appIndex.isEven {
                    let border = WindowManager.instance.display(.border, at: CGPoint(x: borderXPosition, y: screenFrame.minY)) as? BorderViewController
                    border?.screenID = screen
                    borderForScreen[screen] = border
                }
            }
        }
    }

    func menuForApp(id: Int) -> MenuViewController? {
        return menuForID[id]
    }

    func borderForApp(id: Int) -> BorderViewController? {
        let screen = (id / Configuration.appsPerScreen) + 1
        return borderForScreen[screen]
    }
}
