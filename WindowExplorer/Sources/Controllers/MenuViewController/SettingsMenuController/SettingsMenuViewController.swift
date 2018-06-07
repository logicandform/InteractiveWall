//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum SettingsTypes {
    case showLabels
    case showMiniMap
    case showLightbox
    case schools
    case events
    case organizations
    case artifacts

    var color: NSColor {
        switch self {
        case .showLabels:
            return style.menuSelectedColor
        case .showMiniMap:
            return style.menuSelectedColor
        case .showLightbox:
            return style.menuSelectedColor
        case .schools:
            return style.schoolColor
        case .events:
            return style.eventColor
        case .organizations:
            return style.organizationColor
        case .artifacts:
            return style.artifactColor
        }
    }

    var secondaryColor: NSColor {
        switch self {
        case .showLabels:
            return style.menuSecondarySelectedColor
        case .showMiniMap:
            return style.menuSecondarySelectedColor
        case .showLightbox:
            return style.menuSecondarySelectedColor
        case .schools:
            return style.schoolSecondarySelectedColor
        case .events:
            return style.eventSecondarySelectedColor
        case .organizations:
            return style.organizationSecondarySelectedColor
        case .artifacts:
            return style.artifactSecondarySelectedColor
        }
    }
}


class SettingsMenuViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "SettingsMenu")

    @IBOutlet weak var labelsText: NSTextField!
    @IBOutlet weak var miniMapText: NSTextField!
    @IBOutlet weak var lightboxText: NSTextField!
    @IBOutlet weak var schoolsText: NSTextField!
    @IBOutlet weak var eventsText: NSTextField!
    @IBOutlet weak var organizationsText: NSTextField!
    @IBOutlet weak var artifactsText: NSTextField!

    var gestureManager: GestureManager!
    private var labelsSwitch: SwitchControl?
    private var miniMapSwitch: SwitchControl?
    private var lightboxSwitch: SwitchControl?
    private var schoolsSwitch: SwitchControl?
    private var eventsSwitch: SwitchControl?
    private var organizationsSwitch: SwitchControl?
    private var artifactsSwitch: SwitchControl?

    private var switchForSettingsType = [SettingsTypes: SwitchControl?]()
    private var textFieldForSettingsType = [SettingsTypes: NSTextField]()


    // MARK: Life-cycle 

    override func viewDidLoad() {
        super.viewDidLoad()

        gestureManager = GestureManager(responder: self)

        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

//        switchForSettingsType = [.showLabels: labelsSwitch, .showMiniMap: miniMapSwitch, .showLightbox: lightboxSwitch, .schools: schoolsSwitch, .events: eventsSwitch, .organizations: organizationsSwitch, .artifacts: artifactsSwitch]
        textFieldForSettingsType = [.showLabels: labelsText, .showMiniMap: miniMapText, .showLightbox: lightboxText, .schools: schoolsText, .events: eventsText, .organizations: organizationsText, .artifacts: artifactsText]

        setupSwitches()
        setupGestures()
    }


    // MARK: Setup

    private func setupSwitches() {
        labelsSwitch = setupSwitch(for: .showLabels)
        miniMapSwitch = setupSwitch(for: .showMiniMap)
        lightboxSwitch = setupSwitch(for: .showLightbox)
        schoolsSwitch = setupSwitch(for: .schools)
        eventsSwitch = setupSwitch(for: .events)
        organizationsSwitch = setupSwitch(for: .organizations)
        artifactsSwitch = setupSwitch(for: .artifacts)
    }

    private func setupSwitch(for type: SettingsTypes) -> SwitchControl? {
        guard let textField = textFieldForSettingsType[type] else {
            return nil
        }

        let toggleSwitch: SwitchControl = {
            let toggle = SwitchControl(isOn: true, frame: NSRect(x: 0, y: 0, width: 32, height: 16))
            toggle.knobBackgroundColor = type.color
            toggle.disabledKnobBackgroundColor = style.toggleUnselectedColor
            toggle.tintColor = type.secondaryColor
            toggle.disabledBackgroundColor = style.toggleSecondaryUnselectedColor
            return toggle
        }()

        view.addSubview(toggleSwitch)
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        toggleSwitch.topAnchor.constraint(equalTo: textField.topAnchor).isActive = true
        toggleSwitch.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        toggleSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        return toggleSwitch
    }

    private func setupGestures() {
        guard let labelsSwitch = labelsSwitch else {
            return
        }

        let toggleTap = TapGestureRecognizer()
        gestureManager.add(toggleTap, to: labelsSwitch)
        toggleTap.gestureUpdated = handleToggle(_:)
    }


    // MARK: Gesture Handling

    private func handleToggle(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        if let labelsSwitch = labelsSwitch {
            labelsSwitch.isOn = !labelsSwitch.isOn
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
        return view.frame.contains(position)
    }
}
