//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


protocol SettingsDelegate: class {
    func settingsTimeoutFired()
}


class SettingsMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")

    @IBOutlet weak var labelsText: NSTextField!
    @IBOutlet weak var miniMapText: NSTextField!
    @IBOutlet weak var schoolsText: NSTextField!
    @IBOutlet weak var eventsText: NSTextField!
    @IBOutlet weak var labelsSwitchContainer: NSView!
    @IBOutlet weak var miniMapSwitchContainer: NSView!
    @IBOutlet weak var eventsSwitchContainer: NSView!
    @IBOutlet weak var schoolsSwitchContainer: NSView!

    weak var settingsParent: SettingsDelegate?
    var gestureManager: GestureManager!
    private var appID: Int!
    private var currentSettings = Settings()
    private var settingsTimeout: Foundation.Timer?
    private var labelsSwitch: SwitchControl!
    private var miniMapSwitch: SwitchControl!
    private var schoolsSwitch: SwitchControl!
    private var eventsSwitch: SwitchControl!

    private var switchForSettingType = [SettingType: SwitchControl]()
    private var containerForSettingType = [SettingType: NSView]()

    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let group = "group"
        static let settings = "settings"
        static let recordType = "recordType"
        static let status = "status"
    }

    private struct Constants {
        static let settingsTimeoutPeriod = 30.0
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = { [weak self] touch in
            self?.receivedTouch(touch)
        }

        setupSwitches()
        setupGestures()
        setupNotifications()
    }


    // MARK: API

    func set(appID: Int) {
        self.appID = appID
    }

    func reset() {
        view.isHidden = true
        labelsSwitch.isOn = true
        miniMapSwitch.isOn = false
        schoolsSwitch.isOn = true
        eventsSwitch.isOn = true
    }

    func updateOrigin(relativeTo verticalPosition: CGFloat, with buttonFrame: CGRect) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        let translatedPosition = verticalPosition + buttonFrame.origin.y + buttonFrame.height - view.frame.height
        let updatedVerticalPosition = translatedPosition < 0 ? screen.frame.minY : translatedPosition
        view.window?.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: updatedVerticalPosition))
    }

    func resetSettingsTimeout() {
        settingsTimeout?.invalidate()
        settingsTimeout = Timer.scheduledTimer(withTimeInterval: Constants.settingsTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.settingsParent?.settingsTimeoutFired()
        }
    }


    // MARK: Setup

    private func setupSwitches() {
        containerForSettingType = [.labels: labelsSwitchContainer, .miniMap: miniMapSwitchContainer, .schools: schoolsSwitchContainer, .events: eventsSwitchContainer]

        labelsSwitch = setupSwitch(for: .labels)
        miniMapSwitch = setupSwitch(for: .miniMap, on: false)
        schoolsSwitch = setupSwitch(for: .schools)
        eventsSwitch = setupSwitch(for: .events)

        switchForSettingType = [.labels: labelsSwitch, .miniMap: miniMapSwitch, .schools: schoolsSwitch, .events: eventsSwitch]
    }

    private func setupGestures() {
        setupGesture(for: .labels)
        setupGesture(for: .miniMap)
        setupGesture(for: .schools)
        setupGesture(for: .events)
    }

    private func setupNotifications() {
        for notification in SettingsNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Gesture Handling

    private func toggle(_ switchControl: SwitchControl, with type: SettingType) {
        let recordType = type.recordType?.rawValue ?? ""
        var info: JSON = [Keys.id: appID, Keys.recordType: recordType, Keys.status: !switchControl.isOn, Keys.type: ConnectionManager.instance.typeForApp(id: appID).rawValue]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.with(type).name, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        let notificationGroup = info[Keys.group] as? Int
        // Only respond to notifications from the same group, or if group is nil
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            if group != notificationGroup && notificationGroup != nil {
                return
            }
        }

        switch notification.name {
        case SettingsNotification.sync.name:
            if let json = info[Keys.settings] as? JSON, let settings = Settings(json: json) {
                sync(to: settings)
            }
        case SettingsNotification.filter.name:
            if let status = info[Keys.status] as? Bool, let rawRecordType = info[Keys.recordType] as? String, let recordType = RecordType(rawValue: rawRecordType), let setting = SettingType.from(recordType: recordType) {
                currentSettings.set(recordType, on: status)
                switchForSettingType[setting]?.isOn = status
            }
        case SettingsNotification.labels.name:
            if let status = info[Keys.status] as? Bool {
                currentSettings.showLabels = status
                switchForSettingType[.labels]?.isOn = status
            }
        case SettingsNotification.miniMap.name:
            if let status = info[Keys.status] as? Bool {
                currentSettings.showMiniMap = status
                switchForSettingType[.miniMap]?.isOn = status
            }
        default:
            return
        }
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        return bounds.contains(view.frame.transformed(from: window.frame))
    }

    func subview(contains position: CGPoint) -> Bool {
        return view.isHidden ? false : view.frame.contains(position)
    }


    // MARK: Helpers

    private func sync(to settings: Settings) {
        currentSettings.clone(settings)
        for recordType in RecordType.allValues {
            if let settingType = SettingType.from(recordType: recordType) {
                switchForSettingType[settingType]?.isOn = settings.displaying(recordType)
            }
        }
        switchForSettingType[.labels]?.isOn = settings.showLabels
        switchForSettingType[.miniMap]?.isOn = settings.showMiniMap
    }

    private func setupSwitch(for type: SettingType, on: Bool = true) -> SwitchControl? {
        guard let container = containerForSettingType[type] else {
            return nil
        }

        let toggleSwitch: SwitchControl = {
            let toggle = SwitchControl(isOn: on, frame: style.toggleSwitchFrame)
            toggle.knobBackgroundColor = type.color
            toggle.disabledKnobBackgroundColor = style.toggleUnselectedColor
            toggle.tintColor = type.secondaryColor
            toggle.disabledBackgroundColor = style.toggleSecondaryUnselectedColor
            return toggle
        }()

        container.addSubview(toggleSwitch)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        toggleSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        toggleSwitch.heightAnchor.constraint(equalToConstant: style.toggleSwitchFrame.height).isActive = true
        toggleSwitch.widthAnchor.constraint(equalToConstant: style.toggleSwitchFrame.width).isActive = true
        return toggleSwitch
    }

    private func setupGesture(for type: SettingType) {
        guard let toggleSwitch = switchForSettingType[type], let container = containerForSettingType[type] else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: toggleSwitch)
        gestureManager.add(toggleTap, to: container)
        toggleTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.toggle(toggleSwitch, with: type)
            }
        }
    }

    private func receivedTouch(_ touch: Touch) {
        resetSettingsTimeout()
    }
}
