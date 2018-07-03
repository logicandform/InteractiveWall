//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class SettingsManager {
    static let instance = SettingsManager()

    /// The settings for each map application indexed by it's appID
    private var settingsForMap = [Settings]()

    /// The settings for each timeline application indexed by it's appID
    private var settingsForTimeline = [Settings]()

    private struct Keys {
        static let type = "type"
        static let group = "group"
        static let status = "status"
        static let settings = "settings"
        static let recordType = "recordType"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        self.settingsForMap = Array(repeating: Settings(), count: numberOfApps)
        self.settingsForTimeline = Array(repeating: Settings(), count: numberOfApps)
    }


    // MARK: API

    func settingsForType(_ type: ApplicationType) -> [Settings] {
        switch type {
        case .mapExplorer:
            return settingsForMap
        case .timeline:
            return settingsForTimeline
        case .nodeNetwork:
            return []
        }
    }

    func syncApps(group: Int, type: ApplicationType) {
        if let settings = settingsForType(type).at(index: group) {
            postSyncNotification(forGroup: group, with: settings)
        }
    }

    func registerForNotifications() {
        for notification in SettingsNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) else {
            return
        }

        let group = info[Keys.group] as? Int
        let status = info[Keys.status] as? Bool

        switch notification.name {
        case SettingsNotification.sync.name:
            if let json = info[Keys.settings] as? JSON, let settings = Settings(json: json) {
                set(settings, group: group, type: type)
            }
        case SettingsNotification.filter.name:
            if let status = status, let rawRecordType = info[Keys.recordType] as? String, let recordType = RecordType(rawValue: rawRecordType) {
                setFilter(on: status, group: group, recordType: recordType, appType: type)
            }
        case SettingsNotification.labels.name:
            if let status = status {
                setLabels(on: status, group: group, type: type)
            }
        case SettingsNotification.miniMap.name:
            if let status = status {
                setMiniMap(on: status, group: group, type: type)
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

    private func set(_ settings: Settings, group: Int?, type: ApplicationType) {
        let appStates = ConnectionManager.instance.states(for: type).enumerated()

        for (app, state) in appStates {
            if state.group == group {
                switch type {
                case .mapExplorer:
                    settingsForMap[app].clone(settings)
                case .timeline:
                    settingsForTimeline[app].clone(settings)
                case .nodeNetwork:
                    continue
                }
            }
        }
    }

    private func setFilter(on: Bool, group: Int?, recordType: RecordType, appType: ApplicationType) {
        let appStates = ConnectionManager.instance.states(for: appType).enumerated()

        for (app, state) in appStates {
            if state.group == group {
                switch appType {
                case .mapExplorer:
                    settingsForMap[app].set(recordType, on: on)
                case .timeline:
                    settingsForTimeline[app].set(recordType, on: on)
                case .nodeNetwork:
                    continue
                }
            }
        }
    }

    private func setLabels(on: Bool, group: Int?, type: ApplicationType) {
        let appStates = ConnectionManager.instance.states(for: type).enumerated()

        for (app, state) in appStates {
            if state.group == group {
                switch type {
                case .mapExplorer:
                    settingsForMap[app].showLabels = on
                case .timeline:
                    settingsForTimeline[app].showLabels = on
                case .nodeNetwork:
                    continue
                }
            }
        }
    }

    private func setMiniMap(on: Bool, group: Int?, type: ApplicationType) {
        let appStates = ConnectionManager.instance.states(for: type).enumerated()

        for (app, state) in appStates {
            if state.group == group {
                switch type {
                case .mapExplorer:
                    settingsForMap[app].showMiniMap = on
                case .timeline:
                    settingsForTimeline[app].showMiniMap = on
                case .nodeNetwork:
                    continue
                }
            }
        }
    }
}
