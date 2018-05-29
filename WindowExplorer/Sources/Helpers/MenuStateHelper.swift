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

    func splitButtonToggled(by menu: MenuViewController, to status: ToggleStatus) {
        relatedMenus.forEach {
            if $0 !== menu {
                $0.buttonExternallyToggled(type: .splitScreen, selection: status)
            }
        }
    }
}
