//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum ToggleStatus {
    case off
    case on
}


class MenuStateHelper {
    private var relatedMenus = [MenuViewController]()


    // MARK: API

    func add(_ menu: MenuViewController) {
        relatedMenus.append(menu)
    }

    func splitButtonToggled(by tappedMenu: MenuViewController, to status: ToggleStatus) {
        relatedMenus.forEach { menu in
            if menu !== tappedMenu {
                menu.buttonToggled(type: .splitScreen, selection: status)
            }
        }
    }
}
