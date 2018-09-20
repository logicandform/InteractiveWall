//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class TimelineHandler {

    weak var timelineViewController: TimelineViewController?
    private var activityState = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?

    private var pair: Int? {
        return ConnectionManager.instance.pairForApp(id: appID, type: .timeline)
    }

    private var group: Int? {
        return ConnectionManager.instance.groupForApp(id: appID, type: .timeline)
    }

    private struct Keys {
        static let id = "id"
        static let date = "date"
        static let type = "type"
        static let group = "group"
        static let vertical = "vertical"
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(timelineViewController: TimelineViewController) {
        self.timelineViewController = timelineViewController
    }

    deinit {
        ungroupTimer?.invalidate()
    }


    // MARK: API

    /// Determines how to respond to a received rect from another timeline with the type of gesture that triggered the event.
    func handle(date: TimelineDate, fromID: Int, syncing: Bool = false) {
        guard let currentGroup = group, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if pair == nil || pair! == fromID {
            if !syncing {
                activityState = .active
            }
            if let date = adjust(date: date, toApp: appID, fromApp: fromID) {
                timelineViewController?.set(date: date, animated: false)
            }
        }
    }

    func handle(verticalPosition: CGFloat, fromID: Int, syncing: Bool = false) {
        guard let currentGroup = group, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if pair == nil || pair! == fromID {
            if !syncing {
                activityState = .active
            }
            timelineViewController?.set(verticalPosition: verticalPosition, animated: false)
        }
    }

    func send(date: TimelineDate, for gestureState: GestureState = .recognized) {
        // If sending from momentum but another app has interrupted, ignore
        if gestureState == .momentum && pair != nil {
            return
        }

        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.date: date.toJSON, Keys.gesture: gestureState.rawValue]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.rect.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func send(verticalPosition offset: CGFloat, for gestureState: GestureState = .recognized) {
        // If sending from momentum but another app has interrupted, ignore
        if gestureState == .momentum && pair != nil {
            return
        }

        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.vertical: offset, Keys.gesture: gestureState.rawValue]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.vertical.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func syncGroup() {
        guard let controller = timelineViewController else {
            return
        }

        let currentGroup = group ?? appID
        let position = controller.timelineBottomConstraint.constant
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.date: TimelineDate(date: controller.currentDate).toJSON, Keys.vertical: position]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.sync.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func handleAccessibilityNotification(fromID: Int) {
        if let currentGroup = group, currentGroup == fromID {
            timelineViewController?.set(verticalPosition: 0, animated: true)
        }
    }

    func endActivity() {
        ConnectionManager.instance.set(AppState(pair: nil, group: group), for: .timeline, id: appID)
        let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.timeline.rawValue]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func invalidate() {
        ungroupTimer?.invalidate()
    }

    func reset(animated: Bool) {
        timelineViewController?.reset(animated: animated)
    }


    // MARK: Helpers

    private func adjust(date: TimelineDate, toApp app: Int, fromApp pair: Int?) -> TimelineDate? {
        let pairedID = pair ?? app
        return TimelineDate(day: date.day, month: date.month, year: date.year + (appID - pairedID) * TimelineDecadeFlagLayout.yearsPerScreen)
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Configuration.ungroupTimoutDuration, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        if let group = group, group == appID, activityState == .idle {
            let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.timeline.rawValue, Keys.group: appID]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
