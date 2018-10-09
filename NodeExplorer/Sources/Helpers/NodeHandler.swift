//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class NodeHandler {

    let appID: Int
    private var activeNodeCount = 0
    private weak var ungroupTimer: Foundation.Timer?

    private var pair: Int? {
        return ConnectionManager.instance.pairForApp(id: appID, type: .nodeNetwork)
    }

    private var group: Int? {
        return ConnectionManager.instance.groupForApp(id: appID, type: .nodeNetwork)
    }

    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let group = "group"
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(appID: Int) {
        self.appID = appID
    }

    deinit {
        ungroupTimer?.invalidate()
    }


    // MARK: API

    func startActivity() {
        if activeNodeCount.isZero {
            let currentGroup = group ?? appID
            let info: JSON = [Keys.id: appID, Keys.group: currentGroup]
            DistributedNotificationCenter.default().postNotificationName(NodeNotification.pair.name, object: nil, userInfo: info, deliverImmediately: true)
        }
        activeNodeCount += 1
    }

    func endActivity() {
        activeNodeCount -= 1
        if activeNodeCount.isZero {
            let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.nodeNetwork.rawValue]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }

    // Start ungroup timer
    func endUpdates() {
        beginUngroupTimer()
    }


    // MARK: Helpers

    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Configuration.ungroupTimoutDuration, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        if let group = group, group == appID, activeNodeCount.isZero {
            let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.nodeNetwork.rawValue, Keys.group: appID]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
