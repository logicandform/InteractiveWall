//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class TimelineHandler {

    let timeline: NSCollectionView
    private var activityState = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?

    private var pair: Int? {
        return ConnectionManager.instance.pairForApp(id: appID)
    }

    private var group: Int? {
        return ConnectionManager.instance.groupForApp(id: appID)
    }

    private struct Constants {
        static let ungroupTimeoutPeriod = 10.0
    }

    private struct Keys {
        static let id = "id"
        static let group = "group"
        static let rect = "rect"
        static let gesture = "gestureType"
        static let animated = "amimated"
    }


    // MARK: Init

    init(timeline: NSCollectionView) {
        self.timeline = timeline
    }


    // MARK: API

    /// Determines how to respond to a received rect from another timeline with the type of gesture that triggered the event.
    func handle(_ rect: CGRect, fromID: Int, fromGroup: Int, animated: Bool) {
        guard let currentGroup = group, currentGroup == fromGroup, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if pair == nil || pair! == fromID {
            activityState = .active
            let adjustedRect = adjust(rect, toApp: appID, fromApp: fromID)
            timeline.scrollToVisible(adjustedRect)
        }
    }

    func send(_ rect: CGRect, for gestureState: GestureState = .recognized, animated: Bool = false, forced: Bool = false) {
        // If sending from momentum but another app has interrupted, ignore
        if gestureState == .momentum && pair != nil && !forced {
            return
        }

        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.rect: rect.toJSON(), Keys.gesture: gestureState.rawValue, Keys.animated: animated]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.rect.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        ConnectionManager.instance.set(state: AppState(pair: nil, group: group, type: .timeline), forApp: appID)
        let info: JSON = [Keys.id: appID]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func reset(animated: Bool = true) {
        // TODO
    }


    // MARK: Helpers

    private func adjust(_ rect: CGRect, toApp app: Int, fromApp pair: Int?) -> CGRect {
        let pairedID = pair ?? app
        let x = rect.origin.x + CGFloat(appID - pairedID) * rect.size.width

        return CGRect(origin: CGPoint(x: x, y: rect.origin.y), size: rect.size)
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Constants.ungroupTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        guard let group = group, group == appID else {
            return
        }

        if activityState == .idle {
            let info: JSON = [Keys.id: appID, Keys.group: appID]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
