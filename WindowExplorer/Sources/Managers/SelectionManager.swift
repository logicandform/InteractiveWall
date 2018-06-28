//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class SelectionManager {
    static let instance = SelectionManager()

    /// Selections for an app's timeline indexed by it's appID
    var selectionForApp = [Set<Int>]()

    private struct Keys {
        static let group = "group"
        static let index = "index"
        static let state = "state"
        static let selection = "selection"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        self.selectionForApp = Array(repeating: Set<Int>(), count: numberOfApps)
    }


    // MARK: API

    func syncApps(group: Int) {
        let selection = selectionForApp[group]
        postSelectionNotification(forGroup: group, with: selection)
    }

    func registerForNotifications() {
        for notification in TimelineNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        let group = info[Keys.group] as? Int

        switch notification.name {
        case TimelineNotification.selection.name:
            if let selection = info[Keys.selection] as? [Int] {
                set(Set(selection), group: group)
            }
        case TimelineNotification.select.name:
            if let index = info[Keys.index] as? Int, let state = info[Keys.state] as? Bool {
                set(index: index, group: group, selected: state)
            }
        default:
            return
        }
    }

    private func postSelectionNotification(forGroup group: Int, with selection: Set<Int>) {
        let info: JSON = [Keys.group: group, Keys.selection: Array(selection)]
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.selection.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Helpers

    private func set(_ indexSet: Set<Int>, group: Int?) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                selectionForApp[app] = indexSet
            }
        }
    }

    private func set(index: Int, group: Int?, selected: Bool) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                if selected {
                    selectionForApp[app].insert(index)
                } else {
                    selectionForApp[app].remove(index)
                }
            }
        }
    }
}
