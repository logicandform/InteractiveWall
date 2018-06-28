//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Timeline")

    @IBOutlet weak var backgroudImageView: NSImageView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineClipView: NSClipView!
    @IBOutlet weak var timelineBackgroundView: NSView!

    var gestureManager: GestureManager!
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()

    private struct Constants {
        static let timelineCellWidth: CGFloat = 20
        static let timelineSelectedCellWidth: CGFloat = 150
    }

    private struct Keys {
        static let id = "id"
        static let group = "group"
        static let index = "index"
        static let state = "state"
        static let selection = "selection"
    }


    // MARK: Init

    static func instance() -> TimelineViewController {
        let storyboard = NSStoryboard(name: TimelineViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! TimelineViewController
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        TouchManager.instance.register(gestureManager)

        setupTimeline()
        setupBackground()
        setupGestures()
        setupNotifications()
    }


    // MARK: Setup

    private func setupTimeline() {
        timelineHandler = TimelineHandler(timeline: timelineCollectionView)
        ConnectionManager.instance.timelineHandler = timelineHandler
        timelineCollectionView.register(TimelineItemView.self, forItemWithIdentifier: TimelineItemView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineHeaderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier)
        timelineCollectionView.dataSource = source
        timelineScrollView.horizontalScroller?.alphaValue = 0
        timelineBackgroundView.layer?.backgroundColor = style.timelineBackgroundColor.cgColor
    }

    private func setupBackground() {
        let name = appID % Configuration.appsPerScreen == 0 ? "MapLeft" : "MapRight"
        backgroudImageView.image = NSImage(named: name)
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }

        let timelineTapGesture = TapGestureRecognizer()
        gestureManager.add(timelineTapGesture, to: timelineCollectionView)
        timelineTapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnTimeline(gesture)
        }
    }

    private func setupNotifications() {
        for notification in TimelineNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Gesture Handling

    private func didPanOnTimeline(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = timelineCollectionView.visibleRect
            rect.origin.x -= pan.delta.dx
            timelineHandler?.send(rect, for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didTapOnTimeline(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let location = tap.position,
            let indexPath = timelineCollectionView.indexPathForItem(at: location + timelineCollectionView.visibleRect.origin) else {
                return
        }

        let state = source.selectedIndexes.contains(indexPath.item)
        postSelectNotification(for: indexPath.item, state: !state)
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, ConnectionManager.instance.groupForApp(id: appID) == info[Keys.group] as? Int else {
            return
        }

        switch notification.name {
        case TimelineNotification.selection.name:
            if let selection = info[Keys.selection] as? [Int] {
                set(Set(selection))
            }
        case TimelineNotification.select.name:
            if let index = info[Keys.index] as? Int, let state = info[Keys.state] as? Bool {
                set(index, selected: state)
            }
        default:
            return
        }
    }


    // MARK: Helpers

    private func postSelectNotification(for index: Int, state: Bool) {
        var info: JSON = [Keys.id: appID, Keys.index: index, Keys.state: state]
        if let group = ConnectionManager.instance.groupForApp(id: appID) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.select.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func set(_ selection: Set<Int>) {
        // Unselect current indexes that are not in the new selection
        source.selectedIndexes.subtracting(selection).forEach { index in
            set(index, selected: false)
        }
        // Select indexes that are not currently selected
        selection.subtracting(source.selectedIndexes).forEach { index in
            set(index, selected: true)
        }
    }

    private func set(_ index: Int, selected: Bool) {
        if let timelineItem = timelineCollectionView.item(at: IndexPath(item: index, section: 0)) as? TimelineItemView {
            timelineItem.set(highlighted: selected)
        }

        if selected {
            source.selectedIndexes.insert(index)
        } else {
            source.selectedIndexes.remove(index)
        }
    }
}
