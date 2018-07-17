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

    private struct Constants {
        static let ungroupTimeoutPeriod = 10.0
    }

    private struct Keys {
        static let id = "id"
        static let date = "date"
        static let day = "day"
        static let month = "month"
        static let year = "year"
        static let type = "type"
        static let group = "group"
        static let animated = "amimated"
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(timelineViewController: TimelineViewController?) {
        self.timelineViewController = timelineViewController
    }

    deinit {
        ungroupTimer?.invalidate()
    }


    // MARK: API

    /// Determines how to respond to a received rect from another timeline with the type of gesture that triggered the event.
    func handle(date: TimelineDate, fromID: Int, fromGroup: Int, animated: Bool) {
        guard let currentGroup = group, currentGroup == fromGroup, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if pair == nil || pair! == fromID {
            activityState = .active
            adjust(date: date, toApp: appID, fromApp: fromID)
        }
    }

    func send(date: TimelineDate, for gestureState: GestureState = .recognized, animated: Bool = false, forced: Bool = false) {
        // If sending from momentum but another app has interrupted, ignore
        if gestureState == .momentum && pair != nil && !forced {
            return
        }

        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.date: date.toJSON, Keys.gesture: gestureState.rawValue, Keys.animated: animated]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.rect.name, object: nil, userInfo: info, deliverImmediately: true)
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

    func reset(animated: Bool = true) {
        // TODO
    }


    // MARK: Helpers

    private func adjust(date: TimelineDate, toApp app: Int, fromApp pair: Int?) {
        guard let timelineViewController = timelineViewController else {
            return
        }

        let pairedID = pair ?? app
        switch timelineViewController.timelineType {
        case .month:
            timelineViewController.updateCollectionViews(to: TimelineDate(day: date.day, month: date.month + (appID - pairedID), year: date.year))
        case .year:
            timelineViewController.updateCollectionViews(to: TimelineDate(day: date.day, month: date.month, year: date.year + (appID - pairedID)))
        case .decade:
            timelineViewController.updateCollectionViews(to: TimelineDate(day: date.day, month: date.month, year: date.year + (appID - pairedID) * 10))
        case .century:
            return
        }
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
            let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.timeline.rawValue, Keys.group: appID]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
