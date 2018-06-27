//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class TouchManager {
    static let instance = TouchManager()

    private let touchListener = TouchListener()


    // MARK: Init

    /// Use Singleton
    private init() { }


    // MARK: API

    func setupPort() {
        touchListener.listenToPort(named: "AppListener\(appID)")
    }

    func register(_ gestureManager: GestureManager) {
        touchListener.receivedTouch = { touch in
            gestureManager.handle(touch)
        }
    }
}
