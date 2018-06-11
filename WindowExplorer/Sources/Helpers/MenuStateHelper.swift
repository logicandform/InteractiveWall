//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum ToggleStatus {
    case off
    case on
}

private struct Keys {
    static let id = "id"
    static let map = "map"
    static let group = "group"
    static let gesture = "gestureType"
    static let animated = "amimated"
}


class MenuStateHelper {

    private var relatedMenus = [MenuViewController]()


    // MARK: API

    func add(_ menu: MenuViewController) {
        relatedMenus.append(menu)
    }

    func splitButtonToggled(by tappedMenu: MenuViewController, to status: ToggleStatus) {
        relatedMenus.forEach { menu in
            toggleBorder(near: menu, to: status)
            if menu !== tappedMenu {
                menu.buttonToggled(type: .splitScreen, selection: status)
            }
        }
    }


    // MARK: Helpers

    private func toggleBorder(near menu: MenuViewController, to status: ToggleStatus) {
        guard let mapID = calculateMap(for: menu) else {
            return
        }

        let info: JSON = [Keys.id: mapID]
        switch status {
        case .on:
            DistributedNotificationCenter.default().postNotificationName(MapNotification.toggleBorderOn.name, object: nil, userInfo: info, deliverImmediately: true)
        case .off:
            DistributedNotificationCenter.default().postNotificationName(MapNotification.toggleBorderOff.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }

    /// Calculates the map index based off the x-position of the menu and the screens
    private func calculateMap(for menu: MenuViewController) -> Int? {
        guard let window = menu.view.window, let screen = NSScreen.containing(x: window.frame.midX), let screenIndex = screen.orderedIndex else {
            return nil
        }

        let baseMapForScreen = (screenIndex - 1) * Int(Configuration.mapsPerScreen)
        let mapWidth = screen.frame.width / CGFloat(Configuration.mapsPerScreen)
        let mapForScreen = Int((window.frame.origin.x - screen.frame.minX) / mapWidth)
        return mapForScreen + baseMapForScreen
    }
}