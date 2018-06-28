//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class SettingsManager {
    static let instance = SettingsManager()

    /// The settings for an app indexed by it's appID
    var settingsForApp = [Settings]()

    private struct Keys {
        static let group = "group"
        static let settings = "settings"
        static let recordType = "recordType"
        static let status = "status"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        self.settingsForApp = Array(repeating: Settings(), count: numberOfApps)
    }


    // MARK: API

    func syncApps(group: Int) {
        let settings = settingsForApp[group]
        postSyncNotification(forGroup: group, with: settings)
    }

    func registerForNotifications() {
        for notification in SettingsNotification.allValues {
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
        let status = info[Keys.status] as? Bool

        switch notification.name {
        case SettingsNotification.sync.name:
            if let json = info[Keys.settings] as? JSON, let settings = Settings(json: json) {
                set(settings, group: group)
            }
        case SettingsNotification.filter.name:
            if let status = status, let rawRecordType = info[Keys.recordType] as? String, let recordType = RecordType(rawValue: rawRecordType) {
                setFilter(on: status, group: group, type: recordType)
            }
        case SettingsNotification.labels.name:
            if let status = status {
                setLabels(on: status, group: group)
            }
        case SettingsNotification.miniMap.name:
            if let status = status {
                setMiniMap(on: status, group: group)
            }
        default:
            return
        }
    }

    private func postSyncNotification(forGroup group: Int, with settings: Settings) {
        let info: JSON = [Keys.group: group, Keys.settings: settings.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.sync.name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Helpers

    private func set(_ settings: Settings, group: Int?) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                settingsForApp[app].clone(settings)
            }
        }
    }

    private func setFilter(on: Bool, group: Int?, type: RecordType) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                settingsForApp[app].set(type, on: on)
            }
        }
    }

    private func setLabels(on: Bool, group: Int?) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                settingsForApp[app].showLabels = on
            }
        }
    }

    private func setMiniMap(on: Bool, group: Int?) {
        for (app, state) in ConnectionManager.instance.stateForApp.enumerated() {

            // Check if same group
            if state.group == group {
                settingsForApp[app].showMiniMap = on
            }
        }
    }
}
