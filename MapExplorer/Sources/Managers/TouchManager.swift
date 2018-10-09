//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MacGestures


final class TouchManager {
    static let instance = TouchManager()

    private let touchListener = TouchListener()
    private var managerForType = [ApplicationType: GestureManager]()
    private var managerForTouch = [Touch: GestureManager]()


    // MARK: Init

    /// Use Singleton
    private init() { }


    // MARK: API

    func setupPort() {
        touchListener.listenToPort(named: "AppListener\(appID)")
        touchListener.receivedTouch = { [weak self] touch in
            self?.handleTouch(touch)
        }
    }

    func register(_ manager: GestureManager, for type: ApplicationType) {
        managerForType[type] = manager
    }


    // MARK: Helpers

    private func handleTouch(_ touch: Touch) {
        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .moved:
            if let manager = managerForTouch[touch] {
                manager.handle(touch)
            }
        case .up:
            if let manager = managerForTouch[touch] {
                managerForTouch.removeValue(forKey: touch)
                manager.handle(touch)
            }
        }
    }

    private func handleTouchDown(_ touch: Touch) {
        let type = ConnectionManager.instance.typeForApp(id: appID)
        if let manager = managerForType[type] {
            managerForTouch[touch] = manager
            manager.handle(touch)
        }
    }
}
