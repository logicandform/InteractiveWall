//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuStateHelper {
    var menu: MenuViewController?
    var searchMenu: SearchViewController? {
        didSet {
            if searchMenu == nil {
                menu?.buttonToggled(type: .search, selection: .off)
            }
        }
    }


    // MARK: API

    func toggleButton(for type: MenuButtonType, to status: ToggleStatus) {
        switch type {
        case .search:
            if status == .off {
                searchMenu?.animateViewOut()
                searchMenu = nil
            }
        default:
            return
        }
    }
}
